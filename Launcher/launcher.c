/*
 * UT Millenium launcher
 *
 * First run:  finds your Unreal Tournament (Steam) folder, downloads the
 *             official OldUnreal 469e patch, and builds a private game folder
 *             next to this exe ("Game"). Your Steam install is never changed.
 * Every run:  refreshes the mod files and window sizes, then starts the game.
 *
 * Build (from Linux):
 *   python3 -m ziglang cc -target x86_64-windows-gnu -O2 launcher.c -o "UT Millenium.exe" \
 *     -Wl,--subsystem,windows -lwininet -lbcrypt -lshell32 -lole32 -luser32 -lgdi32 -lcomctl32
 */
#ifndef UNICODE
#define UNICODE
#endif
#define _UNICODE
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <wininet.h>
#include <bcrypt.h>
#include <shellapi.h>
#include <shlobj.h>
#include <commctrl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

#define APP_TITLE L"UT Millenium"
#define PATCH_NAME L"OldUnreal-UTPatch469e-Windows-x86.zip"
#define PATCH_URL L"https://github.com/OldUnreal/UnrealTournamentPatches/releases/download/v469e/OldUnreal-UTPatch469e-Windows-x86.zip"
#define PATCH_SHA256 "8c94eb7e990f5480b1fb7bcb1bd15c2512da134dbf01bfa16e7f99f0a8a0ee86"
#define MENU_URL L"UT-Logo-Map.unr?Game=UTMillenium.UTMMenuGame"
#define SETUP_VERSION L"1"

static wchar_t g_Base[MAX_PATH];      /* folder of this exe          */
static wchar_t g_Game[MAX_PATH];      /* <base>\Game                 */
static wchar_t g_UT[MAX_PATH];        /* the user's UT folder        */
static wchar_t g_Error[1024];

static HWND g_Wnd, g_Text, g_Bar;
static volatile LONG g_Done;          /* 1 ok, 2 failed */

/* ------------------------------------------------------------------ utils */

static void PathJoin(wchar_t *out, const wchar_t *a, const wchar_t *b)
{
    swprintf(out, MAX_PATH, L"%ls\\%ls", a, b);
}

static BOOL FileExists(const wchar_t *p)
{
    DWORD a = GetFileAttributesW(p);
    return a != INVALID_FILE_ATTRIBUTES && !(a & FILE_ATTRIBUTE_DIRECTORY);
}

static BOOL DirExists(const wchar_t *p)
{
    DWORD a = GetFileAttributesW(p);
    return a != INVALID_FILE_ATTRIBUTES && (a & FILE_ATTRIBUTE_DIRECTORY);
}

static BOOL IsUTFolder(const wchar_t *dir)
{
    wchar_t p[MAX_PATH];
    PathJoin(p, dir, L"System\\Botpack.u");
    if (!FileExists(p)) return FALSE;
    PathJoin(p, dir, L"Maps\\CTF-Face.unr");
    if (!FileExists(p)) return FALSE;
    PathJoin(p, dir, L"Textures");
    return DirExists(p);
}

static void Status(const wchar_t *fmt, ...)
{
    wchar_t buf[512];
    va_list ap;
    va_start(ap, fmt);
    vswprintf(buf, 512, fmt, ap);
    va_end(ap);
    if (g_Text) SetWindowTextW(g_Text, buf);
}

static void Progress(int pct)
{
    if (g_Bar) PostMessageW(g_Bar, PBM_SETPOS, (WPARAM)pct, 0);
}

static void Fail(const wchar_t *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    vswprintf(g_Error, 1024, fmt, ap);
    va_end(ap);
}

static BOOL MakeDirs(const wchar_t *path)
{
    wchar_t tmp[MAX_PATH];
    wcsncpy(tmp, path, MAX_PATH - 1);
    tmp[MAX_PATH - 1] = 0;
    for (wchar_t *p = tmp + 3; *p; p++) {
        if (*p == L'\\') { *p = 0; CreateDirectoryW(tmp, NULL); *p = L'\\'; }
    }
    CreateDirectoryW(tmp, NULL);
    return DirExists(path);
}

/* Copy every file of src into dst (recursively). Files whose name matches
   skipIfExistsIn\<name> are skipped (used to avoid stale .int files). */
static BOOL CopyTree(const wchar_t *src, const wchar_t *dst, const wchar_t *skipIfExistsIn)
{
    wchar_t pat[MAX_PATH], s[MAX_PATH], d[MAX_PATH], k[MAX_PATH];
    WIN32_FIND_DATAW fd;
    HANDLE h;
    BOOL ok = TRUE;

    MakeDirs(dst);
    PathJoin(pat, src, L"*");
    h = FindFirstFileW(pat, &fd);
    if (h == INVALID_HANDLE_VALUE) return FALSE;
    do {
        if (!wcscmp(fd.cFileName, L".") || !wcscmp(fd.cFileName, L"..")) continue;
        PathJoin(s, src, fd.cFileName);
        PathJoin(d, dst, fd.cFileName);
        if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
            if (!CopyTree(s, d, NULL)) ok = FALSE;
        } else {
            if (skipIfExistsIn) {
                PathJoin(k, skipIfExistsIn, fd.cFileName);
                if (FileExists(k)) continue;
            }
            SetFileAttributesW(d, FILE_ATTRIBUTE_NORMAL);
            if (!CopyFileW(s, d, FALSE)) ok = FALSE;
        }
    } while (FindNextFileW(h, &fd));
    FindClose(h);
    return ok;
}

static void DeleteTree(const wchar_t *dir)
{
    wchar_t from[MAX_PATH + 2];
    SHFILEOPSTRUCTW op;
    memset(from, 0, sizeof(from));
    wcsncpy(from, dir, MAX_PATH);
    memset(&op, 0, sizeof(op));
    op.wFunc = FO_DELETE;
    op.pFrom = from;
    op.fFlags = FOF_NO_UI;
    SHFileOperationW(&op);
}

/* ------------------------------------------------------------- ini files */

typedef struct { char *data; size_t len; } Buf;

static BOOL ReadAll(const wchar_t *path, Buf *b)
{
    HANDLE h = CreateFileW(path, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
    DWORD sz, rd;
    if (h == INVALID_HANDLE_VALUE) return FALSE;
    sz = GetFileSize(h, NULL);
    b->data = (char *)malloc(sz + 1);
    if (!ReadFile(h, b->data, sz, &rd, NULL)) { CloseHandle(h); return FALSE; }
    b->data[rd] = 0;
    b->len = rd;
    CloseHandle(h);
    return TRUE;
}

static BOOL WriteAll(const wchar_t *path, const char *data, size_t len)
{
    HANDLE h = CreateFileW(path, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, 0, NULL);
    DWORD wr;
    if (h == INVALID_HANDLE_VALUE) return FALSE;
    WriteFile(h, data, (DWORD)len, &wr, NULL);
    CloseHandle(h);
    return wr == len;
}

/* A tiny line based ini editor that keeps everything else untouched. */
#define MAXLINES 8192
typedef struct { char *line[MAXLINES]; int n; } Ini;

static BOOL IniLoad(const wchar_t *path, Ini *ini)
{
    Buf b;
    char *p, *e;
    ini->n = 0;
    if (!ReadAll(path, &b)) return FALSE;
    p = b.data;
    while (*p && ini->n < MAXLINES) {
        e = p;
        while (*e && *e != '\n') e++;
        size_t l = e - p;
        if (l && p[l - 1] == '\r') l--;
        ini->line[ini->n] = (char *)malloc(l + 1);
        memcpy(ini->line[ini->n], p, l);
        ini->line[ini->n][l] = 0;
        ini->n++;
        p = *e ? e + 1 : e;
    }
    free(b.data);
    return TRUE;
}

static BOOL IniSave(const wchar_t *path, Ini *ini)
{
    size_t total = 0, pos = 0;
    char *out;
    BOOL ok;
    for (int i = 0; i < ini->n; i++) total += strlen(ini->line[i]) + 2;
    out = (char *)malloc(total + 1);
    for (int i = 0; i < ini->n; i++) {
        size_t l = strlen(ini->line[i]);
        memcpy(out + pos, ini->line[i], l); pos += l;
        out[pos++] = '\r'; out[pos++] = '\n';
    }
    ok = WriteAll(path, out, pos);
    free(out);
    return ok;
}

static int IniFindSection(Ini *ini, const char *sec)
{
    char want[256];
    snprintf(want, sizeof(want), "[%s]", sec);
    for (int i = 0; i < ini->n; i++)
        if (!_stricmp(ini->line[i], want)) return i;
    return -1;
}

static int IniSectionEnd(Ini *ini, int s)
{
    int i = s + 1;
    while (i < ini->n && ini->line[i][0] != '[') i++;
    /* keep trailing blank lines outside */
    while (i - 1 > s && ini->line[i - 1][0] == 0) i--;
    return i;
}

static void IniInsert(Ini *ini, int at, const char *text)
{
    if (ini->n >= MAXLINES) return;
    memmove(&ini->line[at + 1], &ini->line[at], (ini->n - at) * sizeof(char *));
    ini->line[at] = _strdup(text);
    ini->n++;
}

static void IniRemove(Ini *ini, int at)
{
    free(ini->line[at]);
    memmove(&ini->line[at], &ini->line[at + 1], (ini->n - at - 1) * sizeof(char *));
    ini->n--;
}

static int IniEnsureSection(Ini *ini, const char *sec)
{
    char hdr[256];
    int s = IniFindSection(ini, sec);
    if (s >= 0) return s;
    snprintf(hdr, sizeof(hdr), "[%s]", sec);
    IniInsert(ini, ini->n, "");
    IniInsert(ini, ini->n, hdr);
    return ini->n - 1;
}

static void IniSet(Ini *ini, const char *sec, const char *key, const char *val)
{
    char buf[1024];
    size_t kl = strlen(key);
    int s = IniEnsureSection(ini, sec), e = IniSectionEnd(ini, s);
    snprintf(buf, sizeof(buf), "%s=%s", key, val);
    for (int i = s + 1; i < e; i++)
        if (!_strnicmp(ini->line[i], key, kl) && ini->line[i][kl] == '=') {
            free(ini->line[i]);
            ini->line[i] = _strdup(buf);
            return;
        }
    IniInsert(ini, e, buf);
}

static void IniRemoveKey(Ini *ini, const char *sec, const char *key)
{
    size_t kl = strlen(key);
    int s = IniFindSection(ini, sec), e;
    if (s < 0) return;
    e = IniSectionEnd(ini, s);
    for (int i = e - 1; i > s; i--)
        if (!_strnicmp(ini->line[i], key, kl) && ini->line[i][kl] == '=') IniRemove(ini, i);
}

static void IniAdd(Ini *ini, const char *sec, const char *key, const char *val)
{
    char buf[1024];
    int s = IniEnsureSection(ini, sec), e = IniSectionEnd(ini, s);
    snprintf(buf, sizeof(buf), "%s=%s", key, val);
    IniInsert(ini, e, buf);
}

static void ToUtf8(const wchar_t *w, char *out, int n)
{
    WideCharToMultiByte(CP_ACP, 0, w, -1, out, n, NULL, NULL);
}

/* ---------------------------------------------------------- screen sizes */

static void GetSizes(int *pw, int *ph, int *dw, int *dh)
{
    RECT wa;
    int h;
    *dw = GetSystemMetrics(SM_CXSCREEN);
    *dh = GetSystemMetrics(SM_CYSCREEN);
    SystemParametersInfoW(SPI_GETWORKAREA, 0, &wa, 0);
    h = (int)((wa.bottom - wa.top) * 0.86);
    h -= h % 16;
    if (h < 560) h = 560;
    *ph = h;
    *pw = h * 9 / 16;
}

/* Settings that must be right on every start. */
static BOOL ApplyConfig(void)
{
    wchar_t p[MAX_PATH];
    char ut[MAX_PATH * 2], v[64], path[MAX_PATH * 3];
    int pw, ph, dw, dh;
    Ini ini;

    GetSizes(&pw, &ph, &dw, &dh);
    ToUtf8(g_UT, ut, sizeof(ut));

    PathJoin(p, g_Game, L"System\\UnrealTournament.ini");
    if (!IniLoad(p, &ini)) { Fail(L"Can't read %ls", p); return FALSE; }
    IniSet(&ini, "URL", "LocalMap", "UT-Logo-Map.unr");
    IniSet(&ini, "FirstRun", "FirstRun", "469");
    IniSet(&ini, "Engine.Engine", "Console", "UTMillenium.UTMConsole");
    IniRemoveKey(&ini, "Core.System", "Paths");
    IniAdd(&ini, "Core.System", "Paths", "../System/*.u");
    IniAdd(&ini, "Core.System", "Paths", "../Textures/*.utx");
    IniAdd(&ini, "Core.System", "Paths", "../Maps/*.unr");      /* ADD MAPS lands here */
    IniAdd(&ini, "Core.System", "Paths", "../Sounds/*.uax");
    IniAdd(&ini, "Core.System", "Paths", "../Music/*.umx");
    snprintf(path, sizeof(path), "%s\\Maps\\*.unr", ut);     IniAdd(&ini, "Core.System", "Paths", path);
    snprintf(path, sizeof(path), "%s\\Textures\\*.utx", ut); IniAdd(&ini, "Core.System", "Paths", path);
    snprintf(path, sizeof(path), "%s\\Sounds\\*.uax", ut);   IniAdd(&ini, "Core.System", "Paths", path);
    snprintf(path, sizeof(path), "%s\\Music\\*.umx", ut);    IniAdd(&ini, "Core.System", "Paths", path);
    IniSet(&ini, "WinDrv.WindowsClient", "StartupFullscreen", "False");
    IniSet(&ini, "WinDrv.WindowsClient", "StartupBorderless", "False");
    snprintf(v, sizeof(v), "%d", pw); IniSet(&ini, "WinDrv.WindowsClient", "WindowedViewportX", v);
    snprintf(v, sizeof(v), "%d", ph); IniSet(&ini, "WinDrv.WindowsClient", "WindowedViewportY", v);
    snprintf(v, sizeof(v), "%d", dw); IniSet(&ini, "WinDrv.WindowsClient", "FullscreenViewportX", v);
    snprintf(v, sizeof(v), "%d", dh); IniSet(&ini, "WinDrv.WindowsClient", "FullscreenViewportY", v);
    if (!IniSave(p, &ini)) { Fail(L"Can't write %ls", p); return FALSE; }

    PathJoin(p, g_Game, L"System\\UTMillenium.ini");
    ini.n = 0;
    IniLoad(p, &ini);
    snprintf(v, sizeof(v), "%d", pw); IniSet(&ini, "UTMillenium.UTMSettings", "PortraitX", v);
    snprintf(v, sizeof(v), "%d", ph); IniSet(&ini, "UTMillenium.UTMSettings", "PortraitY", v);
    snprintf(v, sizeof(v), "%d", dw); IniSet(&ini, "UTMillenium.UTMSettings", "DesktopX", v);
    snprintf(v, sizeof(v), "%d", dh); IniSet(&ini, "UTMillenium.UTMSettings", "DesktopY", v);
    IniSave(p, &ini);
    return TRUE;
}

/* Copy the mod package from Data\ into the game every start (cheap, and it
   means an updated UT Millenium only has to replace the Data folder). */
static BOOL UpdateModFiles(void)
{
    wchar_t s[MAX_PATH], d[MAX_PATH];
    const wchar_t *files[] = { L"UTMillenium.u", L"UTMillenium.int" };
    for (int i = 0; i < 2; i++) {
        swprintf(s, MAX_PATH, L"%ls\\Data\\%ls", g_Base, files[i]);
        swprintf(d, MAX_PATH, L"%ls\\System\\%ls", g_Game, files[i]);
        SetFileAttributesW(d, FILE_ATTRIBUTE_NORMAL);
        if (!CopyFileW(s, d, FALSE)) { Fail(L"Can't copy %ls (is the Data folder next to the exe?)", s); return FALSE; }
    }
    return TRUE;
}

/* --------------------------------------------------------------- download */

static BOOL Sha256File(const wchar_t *path, char hex[65])
{
    BCRYPT_ALG_HANDLE alg = NULL;
    BCRYPT_HASH_HANDLE hash = NULL;
    unsigned char dig[32], *buf;
    HANDLE f;
    DWORD rd;
    BOOL ok = FALSE;

    f = CreateFileW(path, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
    if (f == INVALID_HANDLE_VALUE) return FALSE;
    buf = (unsigned char *)malloc(1 << 20);
    if (BCryptOpenAlgorithmProvider(&alg, BCRYPT_SHA256_ALGORITHM, NULL, 0) == 0 &&
        BCryptCreateHash(alg, &hash, NULL, 0, NULL, 0, 0) == 0) {
        while (ReadFile(f, buf, 1 << 20, &rd, NULL) && rd > 0)
            BCryptHashData(hash, buf, rd, 0);
        if (BCryptFinishHash(hash, dig, 32, 0) == 0) {
            for (int i = 0; i < 32; i++) sprintf(hex + i * 2, "%02x", dig[i]);
            hex[64] = 0;
            ok = TRUE;
        }
    }
    if (hash) BCryptDestroyHash(hash);
    if (alg) BCryptCloseAlgorithmProvider(alg, 0);
    free(buf);
    CloseHandle(f);
    return ok;
}

static BOOL PatchOk(const wchar_t *path)
{
    char hex[65];
    return FileExists(path) && Sha256File(path, hex) && !strcmp(hex, PATCH_SHA256);
}

static BOOL Download(const wchar_t *url, const wchar_t *dest)
{
    HINTERNET net, req;
    HANDLE f;
    DWORD total = 0, len = sizeof(total), rd, wr, got = 0;
    char *buf;
    BOOL ok = FALSE;

    net = InternetOpenW(L"UTMillenium/1.0", INTERNET_OPEN_TYPE_PRECONFIG, NULL, NULL, 0);
    if (!net) return FALSE;
    req = InternetOpenUrlW(net, url, NULL, 0, INTERNET_FLAG_RELOAD | INTERNET_FLAG_NO_CACHE_WRITE | INTERNET_FLAG_SECURE, 0);
    if (!req) { InternetCloseHandle(net); return FALSE; }
    HttpQueryInfoW(req, HTTP_QUERY_CONTENT_LENGTH | HTTP_QUERY_FLAG_NUMBER, &total, &len, NULL);
    f = CreateFileW(dest, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, 0, NULL);
    if (f != INVALID_HANDLE_VALUE) {
        buf = (char *)malloc(1 << 16);
        ok = TRUE;
        while (InternetReadFile(req, buf, 1 << 16, &rd) && rd > 0) {
            if (!WriteFile(f, buf, rd, &wr, NULL) || wr != rd) { ok = FALSE; break; }
            got += rd;
            if (total) {
                Progress((int)((double)got * 100.0 / total));
                Status(L"Downloading the OldUnreal 469e patch...  %u / %u MB", got >> 20, total >> 20);
            }
        }
        free(buf);
        CloseHandle(f);
    }
    InternetCloseHandle(req);
    InternetCloseHandle(net);
    return ok && got > 1000000;
}

static BOOL RunHidden(wchar_t *cmd)
{
    STARTUPINFOW si;
    PROCESS_INFORMATION pi;
    DWORD code = 1;
    memset(&si, 0, sizeof(si));
    si.cb = sizeof(si);
    si.dwFlags = STARTF_USESHOWWINDOW;
    si.wShowWindow = SW_HIDE;
    if (!CreateProcessW(NULL, cmd, NULL, NULL, FALSE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi)) return FALSE;
    WaitForSingleObject(pi.hProcess, INFINITE);
    GetExitCodeProcess(pi.hProcess, &code);
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    return code == 0;
}

/* ------------------------------------------------------------------ setup */

static DWORD WINAPI SetupThread(LPVOID unused)
{
    wchar_t zip[MAX_PATH], tmp[MAX_PATH], s[MAX_PATH], d[MAX_PATH], cmd[2048], dl[MAX_PATH];
    wchar_t *profile;
    Ini ini;
    (void)unused;

    /* 1. the patch: next to the exe, in Data, in Downloads, or download it */
    Progress(0);
    Status(L"Looking for the OldUnreal 469e patch...");
    swprintf(zip, MAX_PATH, L"%ls\\Data\\%ls", g_Base, PATCH_NAME);
    if (!PatchOk(zip)) {
        swprintf(s, MAX_PATH, L"%ls\\%ls", g_Base, PATCH_NAME);
        profile = _wgetenv(L"USERPROFILE");
        if (profile) swprintf(dl, MAX_PATH, L"%ls\\Downloads\\%ls", profile, PATCH_NAME); else dl[0] = 0;
        if (PatchOk(s)) CopyFileW(s, zip, FALSE);
        else if (dl[0] && PatchOk(dl)) CopyFileW(dl, zip, FALSE);
        else {
            Status(L"Downloading the OldUnreal 469e patch (101 MB)...");
            if (!Download(PATCH_URL, zip)) {
                Fail(L"Couldn't download the OldUnreal patch.\n\nCheck your internet connection, or download\n%ls\nfrom github.com/OldUnreal/UnrealTournamentPatches (release v469e)\nand put it next to UT Millenium.exe, then start again.", PATCH_NAME);
                goto fail;
            }
        }
        if (!PatchOk(zip)) {
            DeleteFileW(zip);
            Fail(L"The downloaded patch file is damaged (checksum mismatch). Please try again.");
            goto fail;
        }
    }

    /* 2. fresh game folder */
    Progress(0);
    Status(L"Copying your Unreal Tournament system files...");
    if (DirExists(g_Game)) DeleteTree(g_Game);
    PathJoin(tmp, g_Game, L"_patch");
    if (!MakeDirs(tmp)) { Fail(L"Can't create %ls", g_Game); goto fail; }

    /* 3. unpack the patch with Windows' own tar */
    Status(L"Unpacking the OldUnreal 469e patch...");
    swprintf(cmd, 2048, L"\"%ls\\System32\\tar.exe\" -xf \"%ls\" -C \"%ls\"", _wgetenv(L"SystemRoot"), zip, tmp);
    if (!RunHidden(cmd)) { Fail(L"Couldn't unpack the patch (tar.exe failed)."); goto fail; }
    Progress(30);

    /* 4. System = your UT System + patch on top (old .int files that the
          patch replaces are left out) */
    Status(L"Building the UT Millenium game folder...");
    PathJoin(s, g_UT, L"System");
    PathJoin(d, g_Game, L"System");
    {
        wchar_t loc[MAX_PATH];
        PathJoin(loc, tmp, L"SystemLocalized\\int");
        if (!CopyTree(s, d, loc)) { Fail(L"Couldn't copy %ls", s); goto fail; }
    }
    Progress(55);
    PathJoin(s, tmp, L"System");
    if (!CopyTree(s, d, NULL)) { Fail(L"Couldn't copy the patch files."); goto fail; }
    PathJoin(s, tmp, L"SystemLocalized\\int");
    CopyTree(s, d, NULL);                                    /* English texts */
    PathJoin(s, tmp, L"Textures");
    PathJoin(d, g_Game, L"Textures");
    CopyTree(s, d, NULL);                                    /* patched fonts */
    Progress(80);

    /* 5. fresh ini files from the patch defaults */
    PathJoin(s, g_Game, L"System\\Default.ini");
    PathJoin(d, g_Game, L"System\\UnrealTournament.ini");
    if (!CopyFileW(s, d, FALSE)) { Fail(L"Default.ini missing from the patch."); goto fail; }
    PathJoin(s, g_Game, L"System\\DefUser.ini");
    PathJoin(d, g_Game, L"System\\User.ini");
    CopyFileW(s, d, FALSE);
    if (IniLoad(d, &ini)) {
        IniSet(&ini, "Botpack.TournamentPlayer", "bAutoTaunt", "True");
        IniSave(d, &ini);
    }
    PathJoin(s, g_Game, L"System\\UTMillenium.ini");
    DeleteFileW(s);

    DeleteTree(tmp);
    if (!UpdateModFiles() || !ApplyConfig()) goto fail;

    /* 6. remember where UT lives */
    {
        char ut[MAX_PATH * 2];
        PathJoin(d, g_Game, L"utpath.txt");
        WideCharToMultiByte(CP_UTF8, 0, g_UT, -1, ut, sizeof(ut), NULL, NULL);
        WriteAll(d, ut, strlen(ut));
        PathJoin(d, g_Game, L"setup.ok");
        WriteAll(d, "1", 1);
    }
    Progress(100);
    Status(L"Done! Starting UT Millenium...");
    InterlockedExchange(&g_Done, 1);
    PostMessageW(g_Wnd, WM_CLOSE, 0, 0);
    return 0;

fail:
    InterlockedExchange(&g_Done, 2);
    PostMessageW(g_Wnd, WM_CLOSE, 0, 0);
    return 0;
}

static LRESULT CALLBACK WndProc(HWND h, UINT m, WPARAM w, LPARAM l)
{
    if (m == WM_CLOSE) {
        if (!g_Done) return 0;   /* don't close while working */
        DestroyWindow(h);
        return 0;
    }
    if (m == WM_DESTROY) { PostQuitMessage(0); return 0; }
    if (m == WM_CTLCOLORSTATIC) {
        SetBkMode((HDC)w, TRANSPARENT);
        return (LRESULT)GetStockObject(WHITE_BRUSH);
    }
    return DefWindowProcW(h, m, w, l);
}

static BOOL RunSetup(HINSTANCE inst)
{
    WNDCLASSW wc;
    MSG msg;
    HFONT font;
    INITCOMMONCONTROLSEX icc = { sizeof(icc), ICC_PROGRESS_CLASS };
    int sw = GetSystemMetrics(SM_CXSCREEN), sh = GetSystemMetrics(SM_CYSCREEN);

    InitCommonControlsEx(&icc);
    memset(&wc, 0, sizeof(wc));
    wc.lpfnWndProc = WndProc;
    wc.hInstance = inst;
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)GetStockObject(WHITE_BRUSH);
    wc.lpszClassName = L"UTMSetup";
    RegisterClassW(&wc);

    g_Wnd = CreateWindowW(L"UTMSetup", L"UT Millenium - first time setup",
        WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX, (sw - 520) / 2, (sh - 170) / 2, 520, 170,
        NULL, NULL, inst, NULL);
    font = CreateFontW(-15, 0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET, 0, 0, CLEARTYPE_QUALITY, 0, L"Segoe UI");
    g_Text = CreateWindowW(L"STATIC", L"Starting...", WS_CHILD | WS_VISIBLE, 20, 20, 470, 44, g_Wnd, NULL, inst, NULL);
    SendMessageW(g_Text, WM_SETFONT, (WPARAM)font, TRUE);
    g_Bar = CreateWindowW(PROGRESS_CLASSW, NULL, WS_CHILD | WS_VISIBLE, 20, 76, 470, 22, g_Wnd, NULL, inst, NULL);
    SendMessageW(g_Bar, PBM_SETRANGE, 0, MAKELPARAM(0, 100));
    ShowWindow(g_Wnd, SW_SHOW);
    UpdateWindow(g_Wnd);

    CreateThread(NULL, 0, SetupThread, NULL, 0, NULL);
    while (GetMessageW(&msg, NULL, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return g_Done == 1;
}

/* ------------------------------------------------------- finding UT on disk */

static BOOL TryUT(const wchar_t *dir)
{
    if (dir && dir[0] && IsUTFolder(dir)) {
        wcsncpy(g_UT, dir, MAX_PATH - 1);
        size_t l = wcslen(g_UT);
        while (l > 3 && (g_UT[l - 1] == L'\\' || g_UT[l - 1] == L'/')) g_UT[--l] = 0;
        return TRUE;
    }
    return FALSE;
}

static BOOL RegString(HKEY root, const wchar_t *key, const wchar_t *val, wchar_t *out, DWORD cch)
{
    DWORD sz = cch * sizeof(wchar_t);
    return RegGetValueW(root, key, val, RRF_RT_REG_SZ | RRF_SUBKEY_WOW6464KEY, NULL, out, &sz) == ERROR_SUCCESS ||
           (sz = cch * sizeof(wchar_t), RegGetValueW(root, key, val, RRF_RT_REG_SZ | RRF_SUBKEY_WOW6432KEY, NULL, out, &sz) == ERROR_SUCCESS);
}

static BOOL FindUT(void)
{
    wchar_t p[MAX_PATH], steam[MAX_PATH], vdf[MAX_PATH], lib[MAX_PATH];
    const wchar_t *guess[] = {
        L"C:\\Steam\\steamapps\\common\\Unreal Tournament",
        L"C:\\Program Files (x86)\\Steam\\steamapps\\common\\Unreal Tournament",
        L"C:\\Program Files\\Steam\\steamapps\\common\\Unreal Tournament",
        L"D:\\Steam\\steamapps\\common\\Unreal Tournament",
        L"D:\\SteamLibrary\\steamapps\\common\\Unreal Tournament",
        L"E:\\SteamLibrary\\steamapps\\common\\Unreal Tournament",
        L"C:\\GOG Games\\Unreal Tournament GOTY",
        L"C:\\UnrealTournament",
        NULL };
    Buf b;

    /* Steam's own uninstall entry for UT (app 13240) */
    if (RegString(HKEY_LOCAL_MACHINE, L"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Steam App 13240",
                  L"InstallLocation", p, MAX_PATH) && TryUT(p)) return TRUE;

    /* every Steam library folder */
    if (RegString(HKEY_CURRENT_USER, L"Software\\Valve\\Steam", L"SteamPath", steam, MAX_PATH)) {
        for (wchar_t *c = steam; *c; c++) if (*c == L'/') *c = L'\\';
        swprintf(p, MAX_PATH, L"%ls\\steamapps\\common\\Unreal Tournament", steam);
        if (TryUT(p)) return TRUE;
        swprintf(vdf, MAX_PATH, L"%ls\\steamapps\\libraryfolders.vdf", steam);
        if (ReadAll(vdf, &b)) {
            char *q = b.data;
            while ((q = strstr(q, "\"path\"")) != NULL) {
                char *a = strchr(q + 6, '"'), *e;
                if (!a) break;
                e = strchr(a + 1, '"');
                if (!e) break;
                char tmp[MAX_PATH * 2];
                int n = 0;
                for (char *c = a + 1; c < e && n < (int)sizeof(tmp) - 1; c++) {
                    if (c[0] == '\\' && c[1] == '\\') c++;   /* vdf escapes backslashes */
                    tmp[n++] = *c;
                }
                tmp[n] = 0;
                MultiByteToWideChar(CP_UTF8, 0, tmp, -1, lib, MAX_PATH);
                swprintf(p, MAX_PATH, L"%ls\\steamapps\\common\\Unreal Tournament", lib);
                if (TryUT(p)) { free(b.data); return TRUE; }
                q = e + 1;
            }
            free(b.data);
        }
    }
    for (int i = 0; guess[i]; i++) if (TryUT(guess[i])) return TRUE;
    return FALSE;
}

static BOOL BrowseUT(HWND owner)
{
    BROWSEINFOW bi;
    wchar_t dir[MAX_PATH];
    PIDLIST_ABSOLUTE pidl;

    for (;;) {
        memset(&bi, 0, sizeof(bi));
        bi.hwndOwner = owner;
        bi.lpszTitle = L"Choose your Unreal Tournament folder (the one with the System, Maps and Textures folders inside):";
        bi.ulFlags = BIF_RETURNONLYFSDIRS | BIF_NEWDIALOGSTYLE;
        pidl = SHBrowseForFolderW(&bi);
        if (!pidl) return FALSE;
        SHGetPathFromIDListW(pidl, dir);
        CoTaskMemFree(pidl);
        if (TryUT(dir)) return TRUE;
        MessageBoxW(owner, L"That folder doesn't look like Unreal Tournament.\n\nPick the folder that contains System, Maps and Textures "
                           L"(for Steam usually ...\\steamapps\\common\\Unreal Tournament).", APP_TITLE, MB_ICONWARNING);
    }
}

static BOOL ChooseUT(void)
{
    wchar_t msg[1024];
    int r;

    if (FindUT()) {
        swprintf(msg, 1024,
            L"Found Unreal Tournament here:\n\n%ls\n\nUse this folder?\n\n"
            L"Yes = set up UT Millenium (downloads the free OldUnreal 469e patch, about 101 MB; your Steam files are not changed)\n"
            L"No = choose another folder", g_UT);
        r = MessageBoxW(NULL, msg, APP_TITLE, MB_YESNOCANCEL | MB_ICONQUESTION);
        if (r == IDYES) return TRUE;
        if (r == IDCANCEL) return FALSE;
    } else {
        MessageBoxW(NULL, L"UT Millenium needs Unreal Tournament (GOTY, e.g. the Steam version).\n\n"
                          L"I couldn't find it automatically, so please show me where it is.", APP_TITLE, MB_ICONINFORMATION);
    }
    return BrowseUT(NULL);
}

static BOOL LoadSavedUT(void)
{
    wchar_t p[MAX_PATH];
    Buf b;
    PathJoin(p, g_Game, L"setup.ok");
    if (!FileExists(p)) return FALSE;
    PathJoin(p, g_Game, L"System\\UnrealTournament.exe");
    if (!FileExists(p)) return FALSE;
    PathJoin(p, g_Game, L"utpath.txt");
    if (!ReadAll(p, &b)) return FALSE;
    MultiByteToWideChar(CP_UTF8, 0, b.data, -1, p, MAX_PATH);
    free(b.data);
    return TryUT(p);
}

/* ------------------------------------------------------------------- main */

static HANDLE Launch(void)
{
    wchar_t exe[MAX_PATH], dir[MAX_PATH], cmd[2048];
    STARTUPINFOW si;
    PROCESS_INFORMATION pi;

    PathJoin(dir, g_Game, L"System");
    PathJoin(exe, dir, L"UnrealTournament.exe");
    swprintf(cmd, 2048, L"\"%ls\" %ls", exe, MENU_URL);
    memset(&si, 0, sizeof(si));
    si.cb = sizeof(si);
    if (!CreateProcessW(exe, cmd, NULL, NULL, FALSE, 0, NULL, dir, &si, &pi)) {
        Fail(L"Couldn't start %ls (error %lu).", exe, GetLastError());
        return NULL;
    }
    CloseHandle(pi.hThread);
    return pi.hProcess;
}

/* ------------------------------------------------------------- ADD MAPS */

static int g_Maps, g_Extra;

static const wchar_t *TargetFor(const wchar_t *name)
{
    const wchar_t *ext = wcsrchr(name, L'.');
    if (!ext) return NULL;
    if (!_wcsicmp(ext, L".unr")) return L"Maps";
    if (!_wcsicmp(ext, L".utx")) return L"Textures";
    if (!_wcsicmp(ext, L".uax")) return L"Sounds";
    if (!_wcsicmp(ext, L".umx")) return L"Music";
    if (!_wcsicmp(ext, L".u") || !_wcsicmp(ext, L".int")) return L"System";
    return NULL;
}

static void ImportFolder(const wchar_t *dir, int depth);

static void ImportZip(const wchar_t *zip, int depth)
{
    wchar_t tmp[MAX_PATH], cmd[2048];
    static int n;
    swprintf(tmp, MAX_PATH, L"%ls\_import%d", g_Game, ++n);
    DeleteTree(tmp);
    MakeDirs(tmp);
    swprintf(cmd, 2048, L"\"%ls\\System32\\tar.exe\" -xf \"%ls\" -C \"%ls\"", _wgetenv(L"SystemRoot"), zip, tmp);
    if (RunHidden(cmd)) ImportFolder(tmp, depth + 1);
    DeleteTree(tmp);
}

static void ImportFolder(const wchar_t *dir, int depth)
{
    wchar_t pat[MAX_PATH], s[MAX_PATH], d[MAX_PATH], sub[MAX_PATH];
    WIN32_FIND_DATAW fd;
    HANDLE h;
    const wchar_t *t;
    const wchar_t *ext;

    if (depth > 6) return;
    PathJoin(pat, dir, L"*");
    h = FindFirstFileW(pat, &fd);
    if (h == INVALID_HANDLE_VALUE) return;
    do {
        if (!wcscmp(fd.cFileName, L".") || !wcscmp(fd.cFileName, L"..")) continue;
        PathJoin(s, dir, fd.cFileName);
        if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) { ImportFolder(s, depth + 1); continue; }
        ext = wcsrchr(fd.cFileName, L'.');
        if (ext && !_wcsicmp(ext, L".zip")) { ImportZip(s, depth); continue; }
        t = TargetFor(fd.cFileName);
        if (!t) continue;
        PathJoin(sub, g_Game, t);
        MakeDirs(sub);
        PathJoin(d, sub, fd.cFileName);
        /* never replace the game's own packages */
        if (!wcscmp(t, L"System") && FileExists(d)) continue;
        if (!wcscmp(t, L"Textures") || !wcscmp(t, L"Sounds") || !wcscmp(t, L"Music")) {
            wchar_t orig[MAX_PATH];
            swprintf(orig, MAX_PATH, L"%ls\\%ls\\%ls", g_UT, t, fd.cFileName);
            if (FileExists(orig)) continue;
        }
        if (!wcscmp(t, L"Maps")) {
            wchar_t orig[MAX_PATH];
            swprintf(orig, MAX_PATH, L"%ls\\Maps\\%ls", g_UT, fd.cFileName);
            if (FileExists(orig)) continue;
        }
        if (CopyFileW(s, d, FALSE)) {
            if (!wcscmp(t, L"Maps")) g_Maps++; else g_Extra++;
        }
    } while (FindNextFileW(h, &fd));
    FindClose(h);
}

static void AddMaps(void)
{
    BROWSEINFOW bi;
    wchar_t dir[MAX_PATH], msg[512];
    PIDLIST_ABSOLUTE pidl;

    memset(&bi, 0, sizeof(bi));
    bi.lpszTitle = L"ADD MAPS: choose a folder with Unreal Tournament maps (.unr files or .zip downloads). Subfolders are included.";
    bi.ulFlags = BIF_RETURNONLYFSDIRS | BIF_NEWDIALOGSTYLE;
    pidl = SHBrowseForFolderW(&bi);
    if (!pidl) return;
    SHGetPathFromIDListW(pidl, dir);
    CoTaskMemFree(pidl);
    g_Maps = g_Extra = 0;
    ImportFolder(dir, 0);
    if (g_Maps)
        swprintf(msg, 512, L"Added %d map(s) and %d support file(s).\n\nThey are in the random pick now (Settings > Maps lets you switch them off).", g_Maps, g_Extra);
    else
        swprintf(msg, 512, L"No new maps found in that folder.");
    MessageBoxW(NULL, msg, APP_TITLE, MB_ICONINFORMATION);
}

/* After the game closes: did the player press ADD MAPS? */
static BOOL TakeAddMapsRequest(void)
{
    wchar_t p[MAX_PATH];
    Ini ini;
    int s, e;
    BOOL req = FALSE;
    PathJoin(p, g_Game, L"System\\UTMillenium.ini");
    if (!IniLoad(p, &ini)) return FALSE;
    s = IniFindSection(&ini, "UTMillenium.UTMSettings");
    if (s < 0) return FALSE;
    e = IniSectionEnd(&ini, s);
    for (int i = s + 1; i < e; i++)
        if (!_stricmp(ini.line[i], "bAddMapsRequest=True")) req = TRUE;
    if (req) {
        IniSet(&ini, "UTMillenium.UTMSettings", "bAddMapsRequest", "False");
        IniSave(p, &ini);
    }
    return req;
}

int WINAPI wWinMain(HINSTANCE inst, HINSTANCE prev, PWSTR args, int show)
{
    wchar_t *slash;
    BOOL force = args && (wcsstr(args, L"/setup") || wcsstr(args, L"-setup"));
    (void)prev; (void)show;

    SetProcessDPIAware();
    CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);
    GetModuleFileNameW(NULL, g_Base, MAX_PATH);
    slash = wcsrchr(g_Base, L'\\');
    if (slash) *slash = 0;
    PathJoin(g_Game, g_Base, L"Game");

    if (force || !LoadSavedUT()) {
        if (!ChooseUT()) return 0;
        if (!RunSetup(inst)) {
            MessageBoxW(NULL, g_Error[0] ? g_Error : L"Setup failed.", APP_TITLE, MB_ICONERROR);
            return 1;
        }
    } else {
        if (!UpdateModFiles() || !ApplyConfig()) {
            MessageBoxW(NULL, g_Error, APP_TITLE, MB_ICONERROR);
            return 1;
        }
    }

    for (;;) {
        HANDLE game = Launch();
        if (!game) {
            MessageBoxW(NULL, g_Error, APP_TITLE, MB_ICONERROR);
            return 1;
        }
        WaitForSingleObject(game, INFINITE);
        CloseHandle(game);
        if (!TakeAddMapsRequest()) break;
        AddMaps();
        UpdateModFiles();
        ApplyConfig();
    }
    return 0;
}

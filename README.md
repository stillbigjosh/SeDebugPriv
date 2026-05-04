# SeDebugPriv 

When a compromised user has SeDebugPrivilege assigned to their token but disabled, it can be enabled programmatically and abused to inject shellcode into a SYSTEM-owned process, achieving privilege escalation without needing SeImpersonatePrivilege or local Administrator group membership.

The critical requirement is that the shell must be running under an interactive logon (Type 2) — network logons (Type 3) from PSRemoting or WinRM receive a filtered token where privileges cannot be enabled even if they appear in whoami /priv.

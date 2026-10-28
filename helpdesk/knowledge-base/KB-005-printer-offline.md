# KB-005: Printer offline or jobs stuck

| | |
|---|---|
| **Applies to** | Printers shared from the print server (APP01) |
| **Audience** | Technicians |
| **Time to fix** | 5–15 minutes |
| **Last tested** | _Not yet tested_ |

## Symptoms
- The printer shows **Offline** on the user's computer.
- Jobs sit in the queue showing *Error* or *Printing* and never come out.
- One stuck job blocks everything behind it.

## Before you start
Ask: is it **one user** or **everyone** on that printer? One user is a computer problem. Everyone is a printer or print server problem.

## Fix: one user
1. Check the device: power, paper, error lights. Can others print to it?
2. On the user's computer, open **Settings → Bluetooth & devices → Printers & scanners** → the printer → **Open print queue** → **Printer → Cancel All Documents**.
3. Remove the printer and add it again: **Win + R** → `\\APP01` → double-click the printer.
4. Restart the computer.

## Fix: everyone, or stuck jobs on the server
1. On APP01, open **Print Management** → **Print Servers → APP01 → Printers**. The *Jobs In Queue* column shows the stuck queue.
2. Right-click the printer → **Open Printer Queue** → **Printer → Cancel All Documents**.
3. If jobs **still** won't clear, the Print Spooler is stuck. Clear it in PowerShell on APP01:
   ```powershell
   Stop-Service -Name Spooler -Force
   Remove-Item -Path "$env:SystemRoot\System32\spool\PRINTERS\*" -Force
   Start-Service -Name Spooler
   ```
   > ⚠️ This clears **every** queue on the server. Tell users first, and do it quickly. Anything they printed will need to be sent again.
4. From your own computer, you can clear one printer's jobs remotely without touching the others:
   ```powershell
   Get-PrintJob -ComputerName APP01 -PrinterName 'Finance-Printer' | Remove-PrintJob
   ```

## If that didn't work
| Problem | Next step |
|---|---|
| Can't add the printer: needs administrator to install a driver | Expected since the 2021 "PrintNightmare" security fixes. The driver must be preinstalled or deployed by IT. Escalate. |
| Printer shows offline on the server too | Ping the printer's IP. If it doesn't answer, it's the device or network. |
| Prints garbled text | Wrong driver. Escalate to Systems to update the driver on the server. |

## Escalate when
- Clearing the spooler doesn't fix it, or it keeps jamming → **Systems**.
- A driver must be installed or changed → **Systems**.
- The physical printer shows a hardware error → the printer vendor or facilities.

## Related
- [KB-007: Computer is slow](./KB-007-slow-computer.md)

# ssd''_health_check



An SSD needs to be powered on and used for maximum health. This PowerShell script is intended for periodic use on drives that you are not using regularly. It will run a health check on the drive, along with a read process of all files, thereby renewing the health of the drive.



> Built with AI assistance — developed using Perplexity (Claude Sonnet 4.6).



---



## How to Run



1. Check what drive letter your SSD is assigned on the system.

2. Open PowerShell **as Administrator**.

3. Navigate to the directory where the script is saved.

4. Run the script:



```powershell

.\ssd_health.ps1

```



### Execution Policy



If your execution policy does not allow scripts, run the following first:



`Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process`



`-Scope Process` allows scripts to run only for the current terminal session. The policy reverts automatically when you close PowerShell. Using `-Scope CurrentUser` would make the change permanent, which carries slightly more risk.



---



## What the Script Does



1. **Admin check** — Confirms it is running as Administrator and fails fast with a clear message if not.



2. **Drive validation** — Asks for the drive letter and confirms the drive is present on the system.



3. **Log check** — Looks for an existing log file on the drive itself. If one is found, it summarizes the last run (date, files read, any errors) and asks whether to proceed with a new pass.

&#x20;  - Recommended interval: **once per year** for inactive drives stored at room temperature (68–77°F)

&#x20;  - Every **6 months** if stored in warmer locations such as an attic or garage



4. **Initial space snapshot** — Records total, used, and free GB before anything happens.



5. **CHKDSK** — Runs a read-only filesystem integrity scan, records the exit code, and takes a space snapshot after completion.



6. **SMART data** — Pulls wear level, temperature, power-on hours, and read/write error counts from the drive's internal health counters.



7. **Full file read pass** — The core refresh step. Forcing every stored byte through the SSD controller triggers its internal error correction (ECC), which detects and rewrites any cells whose charge has decayed during long-term unpowered storage.



8. **Failed read summary** — Any files that could not be read are collected and printed as a block at the end, rather than just scrolling past as inline warnings.



9. **Final space snapshot** — Records total, used, and free GB after the read pass completes.



10. **JSON log entry** — Appends a structured log entry to a file stored on the drive itself, so every future run can reference what happened last time. Over multiple runs, the failed-file history serves as a wear map for identifying problem areas.
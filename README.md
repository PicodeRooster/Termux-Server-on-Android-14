# Termux Server on Android 14
## Repurposing old Android into dedicated file server

### Purpose
I own three computers, each with a different operating system. I needed a way to easily store and retrieve data, such as project files and ebooks. I learned a while back a phone can function just as much as a daemon as any other computer, with the caveat of needing to establish a static IP address for it and maintain the battery life. The downside to this is both less storage than a computer and the real possibility of battery death. For this, a backup should be placed to maintain access to the server at all times.

This project also grew out of a real, immediate need: my Linux machine broke down and I couldn't afford to sit around without access to my project files. An old Android phone became the stopgap — and then the permanent solution.

### Steps Taken

1. Charged old phone to full capacity to turn it on
2. Factory Reset the phone to retrieve full storage capacity
3. Turned off all location tracking and Google account setup
4. Removed/disabled bloatware
5. Allow Chrome to side-load external files
6. Installed F-Droid from Chrome browser
7. Allowed F-Droid to install applications
8. Installed Termux from F-Droid
9. Setup server with Termux and launched it
10. Setup storage path for Termux
11. Set a password for Termux
12. Setup static IP address for phone
13. Find username for Termux
14. Generated new SSH keygen on client mac, then push public key to phone
15. Connect with key-only and started uploading files

## What You Need

- An old Android phone (iOS is not viable — background apps get killed too aggressively for a persistent daemon)
- [Termux](https://f-droid.org/en/packages/com.termux/) from **F-Droid**, not the Play Store version (unmaintained/outdated)
- A client machine on the same Wi-Fi network

---

## Part 1: Server Setup (on the phone)

1. Install Termux from F-Droid, open it.
2. Install the SSH daemon:
   ```
   pkg install openssh
   ```
3. Start it:
   ```
   sshd
   ```
   Termux runs unprivileged, so sshd defaults to **port 8022**, not 22.
4. Set a password (Termux has none by default — needed once, to push your first key over):
   ```
   passwd
   ```
5. Find your Termux username
   ```
   whoami        # e.g. u0_a209
   ```

6. Go to phone network settings and set a private IP address.

   Settings > Wi-Fi > Select ISP > Select pencil icon to edit details > Select IP address
   - Set IP setting to static
   - Set desired IP address and appropriate subnet mask

7. Setup Termux's storage folder:
   ```
   termux-setup-storage
   ```
   This allows the Termux server to store files locally. By default, it has no access to the system's storage. When you create this path, you create a sandboxed storage for Termux. Make sure to move all files to one with a UI like the phone's Downloads folder. The path I use for this project is `storage/downloads` to see all files on my phone's local Downloads folder.

---

## Part 2: Client Setup (on your Mac/laptop)

The **private key stays on the client**. The **public key goes on the server** (the phone). Don't generate keys on the phone — generate them on whatever device you're connecting *from*.

1. Generate a key pair:
   ```
   ssh-keygen -t ed25519 -C "mac-to-phone"
   ```
2. Push the public key to the phone (uses the Termux password from setup, one time only):

   **Ubuntu/Debian & mac:**
   ```
   ssh-copy-id -i ~/.ssh/id_ed25519.pub -p 8022 u0_a209@10.0.0.85
   ```

   **Windows:**
   ```
   type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh -p 8022 u0_a209@10.0.0.85 "cat >> ~/.ssh/authorized_keys"
   ```
3. Connect key-only from now on:

   **Ubuntu/Debian & mac:**
   ```
   ssh -i ~/.ssh/id_ed25519 -p 8022 u0_a209@10.0.0.85
   ```

   **Windows:**
   ```
   ssh -i $env:USERPROFILE\.ssh\id_ed25519 -p 8022 u0_a209@10.0.0.85
   ```

If you add another client device later (work laptop, etc.), give it its **own** key pair and push it the same way — don't copy the same private key file across multiple machines.

---

## Part 3: Keeping the Server Alive

Android will kill background apps by default. To keep sshd running:

- Disable battery optimization for Termux (Android Settings > Apps > Termux > Battery)
- Install the Termux:API add-on and run `termux-wake-lock`
  - To release it later: `termux-wake-unlock`
- Install **Termux:Boot** (from F-Droid) so sshd can auto-start on power-on instead of requiring the app to be manually opened:
  ```
  mkdir -p ~/.termux/boot
  nano ~/.termux/boot/start-sshd.sh
  ```
  Contents:
  ```
  #!/data/data/com.termux/files/usr/bin/sh
  sshd
  ```
  Make executable:
  ```
  chmod +x ~/.termux/boot/start-sshd.sh
  ```

---

## Part 4: Transferring Files (scp)

Push a file to the phone:
```
scp -P 8022 -i ~/.ssh/id_ed25519 ~/Downloads/somebook.pdf u0_a209@10.0.0.85:~/
```

Pull a file back:
```
scp -P 8022 -i ~/.ssh/id_ed25519 u0_a209@10.0.0.85:~/somebook.pdf ~/Downloads/
```

**Getting files somewhere other apps can see them:** Termux's home directory is sandboxed — invisible to your ebook reader, gallery, etc. To fix that:

```
termux-setup-storage      # run once in Termux, tap Allow on the permission prompt
mv ~/somebook.pdf ~/storage/downloads/
```

Once `~/storage/downloads` exists, you can scp straight into it going forward.

**Common gotcha:** if a path has spaces and you get a "No such file" error with weird curly quotes (`" "` instead of `" "`), the quotes were mangled by pasting from somewhere with autocorrect. Fixes:
- Type the command, then **drag the file from Finder into Terminal** to auto-insert an escaped path
- Or manually escape spaces: `Python\ Crash\ Course.pdf`

---

## Part 5: Alternative File Sharing (Samba/SMB)

After exploring SSH/scp as the primary transfer method, I wanted to implement **Samba** as a GUI-based alternative — mounting the Linux machine as a network share and browsing it from Android, rather than pushing/pulling files via command line.

### Setup

- Followed the [Ubuntu Samba tutorial](https://ubuntu.com/tutorials/install-and-configure-samba#4-setting-up-user-accounts-and-connecting-to-share), specifically Step 4 (user accounts / share setup)
- Created a Samba account using the computer's existing username, with a separate new password for Samba itself
- Stopped following the tutorial at Step 4 — didn't continue further into the guide

### Client: Solid Explorer (Android)

Android 14 has no native SMB/SMBnative support — shared network connections aren't supported out of the box. This meant a third-party app was required to act as the SMB client:

1. Open Solid Explorer's **Storage Manager**
2. Tap **+** → **LAN/SMB**
3. Linux machine appears as discoverable
4. Go to **Authentication > Username and Password**
5. Enter the Samba credentials created above
6. File share connects successfully

### Results

The final products is a shared network drive where I can easily drag-and-drop folders or files. On my Linux machine, the structure looks like so:

![Final Samba shared network drive on Linux machine.](/assets/termux-server-on-linux.png "Linux/Samba shared network drive")

### Testing note (Linux Mint side)

Tried connecting from Linux Mint's built-in file sharing ("Connect to Server") to test the share — this failed. This is expected: the working client-side path was Solid Explorer on Android, not Linux Mint's own file manager.

## Part 6: Security

I originally created scripts to connect and transfer files. While I was proud to share these, I realized this was an unsecure practice. It not only included the server's static IP address, but was set to Termux's default, insecure 8022 port. 

### Step 1 — Install sshd and locate the config file
**Where: Phone**

```bash
pkg install openssh
```

Config file lives at:
```bash
$PREFIX/etc/ssh/sshd_config
```
(`$PREFIX` is typically `/data/data/com.termux/files/usr`)

sshd is the server software — it needs to live on the machine accepting connections, i.e. the phone.

---

### Step 2 — Generate an SSH key pair
**Where: Client**

```bash
ssh-keygen -t ed25519 -C "your-label-here"
```

Press enter through the prompts, or set a passphrase for extra protection. This creates:
- `~/.ssh/id_ed25519` — private key, **never share this**
- `~/.ssh/id_ed25519.pub` — public key, safe to copy/share

Generate this on the client, not the phone — the private key should stay with the device you're connecting from.

---

### Step 3 — Copy the public key to the phone
**Where: Client (pushes to Phone)**

```bash
ssh-copy-id -p 8022 u0_a123@<phone-ip>
```

(Termux usernames look like `u0_a123` — run `whoami` on the phone if unsure. Port 8022 is Termux's default sshd port at this stage, before you change it in Step 5.)

If `ssh-copy-id` isn't available, do it manually **on the phone**:
```bash
mkdir -p ~/.ssh
echo "paste-your-public-key-contents-here" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

---

### Step 4 — Test key-based login BEFORE disabling passwords
**Where: Client**

```bash
ssh -p 8022 u0_a123@<phone-ip>
```

Confirm you log in without being prompted for a password.

⚠️ **Don't skip this.** If key auth isn't actually working yet and you disable password auth in Step 5, you'll lock yourself out with no way back in.

---

### Step 5 — Edit sshd_config
**Where: Phone**

```bash
nano $PREFIX/etc/ssh/sshd_config
```

Set (or add) these lines:
```
PasswordAuthentication no
PermitRootLogin no
Port 2222
```

Notes:
- Pick a port other than 22 (blocked anyway — Termux can't bind ports below 1024 without root) and other than 8022 (the old default). Avoid obvious SSH-adjacent numbers like 2222/12022 in practice — bots specifically probe those. Something random in the 10000–65535 range is a better real-world choice.
- This is the file that enforces "key-only, no root login" — the core of the lockdown.

---

### Step 6 — Restart sshd
**Where: Phone**

```bash
pkill sshd
sshd
```

This applies the config changes. Termux has no persistent init system, so this restart only lasts for the current session — a reboot or app kill will require restarting sshd manually (or setting up Termux:Boot, a separate step).

---

### Step 7 — Test again on the new port
**Where: Client**

```bash
ssh -p 2222 u0_a123@<phone-ip>
```

(Use whatever port you actually set in Step 5.)

⚠️ **Keep your original session (from Step 4) open** until this new connection is confirmed working. If the new port/config is broken, you still have a working fallback session to fix it from — don't close all sessions until you've verified access.

---
## Part 7: System Diagnostics

The last step is to add additional functionality to the server by running periodic diagnostics. Instead of manually doing so, I created a script that runs on an endless loop and checks basic diagnostics. You will notice this is the only item in `Scripts` without a PowerShell equivalent. That's because this is the only script meant to be run *in* the phone. 

Below, an explanation of `diagnostics.sh`:

```
symbols=("/" "—" "\\" "|")`
```

The symbols array contains all the characters for our simple `cooldown` animation. I saw this on a PowerShell package installation, if I am not mistaken and wanted to create something similar for a while. I used Claude Code for assistance on this part of the script.

```
cooldown()
``` 
This is the function that Claude Code assisted me in creating. All it does is countdown to the given time in seconds and displays the animation while in affect. 

```
main()
```
The main diagnostics logic. More specifically, the script follows these steps:

  1. Find and upgrade packages
   ```
    pkg update && pkg upgrade;
   ```

  2. Check phone's battery health
    ```
    termux-battery-status;
    ```
  3. Check all available storage in phone
    ```
    df -h;
    ```
  4. See network connection information
    ```
    termux-wifi-connectioninfo
    ```
After sleeping for 2 seconds on each step, it runs the cooldown animation, counting down 30 seconds before running the script again. This helps both maintain periodic system checks and is aesthetically pleasing to visualize — it looks cool while it runs.

---
## Scripts

The `Scripts` directory contains useful scripts that hold common commands to interact with the server. Since the server is designed to connect from any major operating system, there is both a `.sh` for Unix-like systems, and a `.ps1` for Windows PowerShell. 

I initially included these scripts, removed them later for security, then re-added them with the port and IP address modified. As they stand, they cannot connect to this project's server, even if on the same LAN. This is intentional. I have a separate version of each of these scripts with the real port and IP address to speed up file transfers when not connected to the Samba share folder on my Linux machine. The scripts on this repository are meant for demonstration. 

Should you like to use them for your own project, be sure to edit to the correct port number and the IP address of your server. If using on Unix-like systems, remember to make them executable before running:

```
chmod +x connect.sh
chmod 755 connect.sh
```

Then call the script like:

```
./connect.sh
```

---

## Technical Difficulties (Samba)

**Attempt 1: Manual install from Samba.org (source)**
- Tried installing directly from the official source at [samba.org](https://www.samba.org/), following their wiki for manual configuration
- Manually installed all missing dependencies/packages, following the guide closely
- Troubleshot issues with the `configure` command and sudo privilege problems
- Despite getting through the build/config process, **could not get Samba to actually start** this way

**Attempt 2: Android 14's lack of native SMB support**
- Android 14 does not support shared network connections natively — no built-in SMB client
- First tried **SambaLite** (to stay within F-Droid) — could not get it to detect the Linux machine
- Asked Claude Code and Gemini for recommendations; both pointed to **Solid Explorer**
- Installed Solid Explorer from the Google Play Store
- Still could not see the Linux machine at first — but it immediately detected a **Windows** machine on the network (Network Discovery had recently been enabled there), confirming the app itself worked correctly
- Reviewed firewall settings, configured to allow SMB connections, retried
- Diagnosis: **Samba itself was not properly installed** on the Linux machine — the real root cause all along

**Resolution**
- Abandoned the manual/source build entirely/home/pico/termux_server/Termux-Server-on-Android-14/README.md
- Switched to the [Ubuntu Samba tutorial](https://ubuntu.com/tutorials/install-and-configure-samba#4-setting-up-user-accounts-and-connecting-to-share) (Part 5 above)
- Worked immediately once Samba was properly installed via the package manager

**Takeaway / Warning for other Linux users**
> If you're on a distro like Ubuntu (or Debian-based), skip the manual samba.org source build — just use the Ubuntu package-based tutorial. It's infinitely simpler and gets you working results without the dependency/config headaches of building from source.
>
> Also worth noting for Android 14 users: native SMB support is gone, so you'll need a third-party app. Solid Explorer worked reliably once Samba itself was properly configured on the server side.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Prompted for a password despite using `-i` | Public key never made it into `authorized_keys` on the phone | Re-run `ssh-copy-id`, or manually check `cat ~/.ssh/authorized_keys` in Termux |
| Key auth silently falls back to password | Wrong permissions on the phone | `chmod 700 ~/.ssh` and `chmod 600 ~/.ssh/authorized_keys` |
| `ssh-copy-id`/password auth fails outright | No password set on the Termux user | Run `passwd` in Termux first |
| `scp: failed to upload file ... to ~/storage/downloads` | `~/storage` doesn't exist yet | Run `termux-setup-storage` in Termux, grant the permission prompt |
| Samba share invisible to Android's file system | Android 14 lacks native SMB support | Use a third-party SMB client app (Solid Explorer recommended) |
| SMB share not discoverable via Solid Explorer | Samba not properly installed on the server | Reinstall Samba via distro package manager (e.g. Ubuntu tutorial), not from source |
| Linux Mint "Connect to Server" fails to reach the share | Expected — client-side SMB test from Mint isn't the intended path | Connect from the Android SMB client (Solid Explorer) instead |

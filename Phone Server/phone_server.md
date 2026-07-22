# Phone Server
## Repurposing old Android into dedicated file server

### Purpose
I own three computers, each with a different operating system. I needed a way to easily store and retrieve data, such as project files and ebooks. I learned a while back a phone can function just as much as a daemon as any other computer, with the caveat of needing to establish a static IP address for it and maintain the battery life. The downside to this is both less storage than a computer and the real possibility of battery death. For this, a backup should be placed to maintain access to the server at all times. 

### Steps Taken

1. Charged old phone to full capacity to turn it on
2. Factory Reset the phone to retrieve full storage capacity
3. Turned off all location tracking and google account setup
4. Removed/disabled bloatware
5. Allow Chrome to side-load files
6. Installed F-Droid from PlayStore
7. Allowed F-Droid to install applications
8. Installed Termux from F-Droid
9. Setup server with Termux and launched it
10. Setup storage path for Termux
11. Set a password for Termux
12. Find username and IP address for Termux
13. Generated new SSH keygen on host mac, then push public key to phone.
14. Connect with key-only and started uploading files.

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
5. Find your Termux username and IP:
   ```
   whoami        # e.g. u0_a209
   ifconfig      # look under wlan0 for your local IP, e.g. 10.0.0.85
   ```
6. Setup Termux's storage folder:
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
- Install **Termux:Boot** so sshd can auto-start on power-on instead of requiring the app to be manually opened

---

## Part 4: Networking Notes

- **Same Wi-Fi:** works immediately using the phone's local IP (e.g. `10.0.0.85`).
- **Remote access:** either forward port 8022 on your router to the phone's local IP, or (recommended) put the phone on a **Tailscale** network instead — gives a stable address reachable from anywhere with zero exposed ports.
- **Mobile data:** carrier-grade NAT means port forwarding won't work at all when the phone is off Wi-Fi — Tailscale is the only reliable option in that case.

---

## Part 5: Transferring Files (scp)

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

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Prompted for a password despite using `-i` | Public key never made it into `authorized_keys` on the phone | Re-run `ssh-copy-id`, or manually check `cat ~/.ssh/authorized_keys` in Termux |
| Key auth silently falls back to password | Wrong permissions on the phone | `chmod 700 ~/.ssh` and `chmod 600 ~/.ssh/authorized_keys` |
| `ssh-copy-id`/password auth fails outright | No password set on the Termux user | Run `passwd` in Termux first |
| `scp: failed to upload file ... to ~/storage/downloads` | `~/storage` doesn't exist yet | Run `termux-setup-storage` in Termux, grant the permission prompt |

---

## Key Takeaways

- Private key = client (the device you connect **from**). Public key = server (the device you connect **to**).
- Each new client gets its own key pair.
- Termux's sshd defaults to port **8022**, always pass `-p 8022` / `-P 8022`.
- `~/` in Termux is sandboxed; `~/storage/...` is the bridge to shared Android storage.
- For anything beyond same-Wi-Fi access, Tailscale beats port forwarding on every axis (security, stability, mobile-data support).
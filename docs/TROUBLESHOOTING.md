# Felsökning

## Apache-modul version 10.x ger fel

**Symptom:**
```
Error: Could not retrieve catalog: Parameter ... is not supported
```

**Lösning:**
```
sudo puppet module uninstall puppetlabs-apache
sudo puppet module install puppetlabs-apache --version 9.1.3
```
## GRUB-fel: "normal.mod not found"

**Symptom:**
```
error: file `/boot/grub/i386-pc/normal.mod' not found.
grub rescue>
```

**Lösning:**
Ändra disk interface från SCSI till IDE i GNS3.

**Symptom:**
Kan inte logga in som root via SSH.

**Lösning:**
Logga in som `debian` först, sedan su -:
```
ssh debian@192.0.2.121
su -
```



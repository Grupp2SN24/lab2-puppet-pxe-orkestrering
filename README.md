
# Lab 2: PXE-boot och Puppet Orkestrering


##Översikt
Automatisk Debian-installation via PXE med efterkonfiguration via Puppet.

**Vad denna labb demonstrerar:**
- PXE-boot (DHCP, TFTP, HTTP)
- Puppet Roles & Profiles pattern
- Automatisk OS-installation via Preseed
- Idempotent configuration management
- Skalbar infrastruktur-orkestrering

## Nätverkstopologi
Master (192.0.2.5)    PXE-Server (192.0.2.10)
deb-auto-1      deb-auto-2
   192.0.2.121     192.0.2.122


### 1. Klona repot

git clone https://github.com/Grupp2SN24/lab2-puppet-pxe-orkestrering.git
cd lab2-puppet-pxe-orkestrering


### 2. Kopiera Puppet-kod till Master
```
sudo cp -r puppet-code/* /etc/puppetlabs/code/environments/production/
```

### 3. Installera Apache-modul
```
cd /etc/puppetlabs/code/environments/production/modules
sudo puppet module install puppetlabs-apache --version 9.1.3
```

**⚠️ VIKTIGT:** Använd version 9.1.3! Version 10.x har en bug!

### 4. Konfigurera nätverk

**På Master och PXE-Server:**
- Statisk IP på ens4 (L2-nät 192.0.2.0/24)
- DHCP på ens5 (NAT för internet)

### 5. Aktivera NAT på PXE-Server
```bash
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf

sudo iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
sudo iptables -A FORWARD -i ens4 -o ens5 -j ACCEPT
sudo iptables -A FORWARD -i ens5 -o ens4 -m state --state RELATED,ESTABLISHED -j ACCEPT

sudo apt install -y iptables-persistent
sudo netfilter-persistent save
```

### 6. Kör Puppet på PXE-Server
```bash
cd /etc/puppetlabs/code/environments/production
sudo puppet apply --environment production \
  --modulepath=/etc/puppetlabs/code/environments/production/modules \
  manifests/site.pp --certname pxe-server
```

### 7. Boota målmaskiner via PXE

**I GNS3:**
- Boot priority: Network
- Disk interface: IDE
- Starta maskinen

Debian installeras automatiskt via PXE! (10-15 min)


## Felsökningar och buggar

**Problem:** Apache-modul version 10.x ger fel
**Lösning:** Använd version 9.1.3

**Problem:** GRUB-fel på målmaskin
**Lösning:** Använd IDE disk interface, inte SCSI

**Problem:** Installationen hittar inte spegelserver
**Lösning:** Kontrollera att NAT fungerar och gateway är 192.0.2.10


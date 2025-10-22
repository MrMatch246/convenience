#!/usr/bin/env python3
"""
WireGuard Project Generator (fixed: PostUp/PostDown use vm_subnet variable)

Usage example:
  python3 gen_wg_project.py --scope scope.txt --clients clients.txt --project LandGard

Requires:
  - wireguard-tools (wg)
"""
import argparse
import subprocess
import sys
from pathlib import Path
import textwrap

def run(cmd, input_data=None):
	p = subprocess.Popen(cmd, stdin=subprocess.PIPE if input_data else None,
	                     stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
	out, err = p.communicate(input_data)
	if p.returncode != 0:
		raise RuntimeError(f"Command failed: {' '.join(cmd)}\n{err}")
	return out.strip()

def wg_keypair():
	priv = run(["wg", "genkey"])
	pub = run(["wg", "pubkey"], input_data=priv + "\n")
	return priv, pub

def write_file(path: Path, content: str):
	path.write_text(content)
	path.chmod(0o600)
	print(f"  wrote {path}")

def build_server_conf(priv, server_addr, listen_port, vm_subnet, peers):
	lines = [
		"[Interface]",
		f"Address = {server_addr}/24",
		f"ListenPort = {listen_port}",
		f"PrivateKey = {priv}",
		"",
		"# Enable IP forwarding",
		"PostUp = sysctl -w net.ipv4.ip_forward=1",
		"PostUp = iptables -I FORWARD -i %i -j ACCEPT",
		"PostDown = iptables -D FORWARD -i %i -j ACCEPT || true",
		"",
		"# NAT for VM subnet when leaving server interface (optional)",
		f"PostUp = iptables -t nat -A POSTROUTING -s {vm_subnet}/24 -o %i -j MASQUERADE",
		f"PostDown = iptables -t nat -D POSTROUTING -s {vm_subnet}/24 -o %i -j MASQUERADE || true",
		"",
	]
	for p in peers:
		lines += [
			"[Peer]",
			f"# {p['name']}",
			f"PublicKey = {p['pub']}",
			"AllowedIPs = " + ", ".join(p['allowed']),
			""
		]
	return "\n".join(lines)

def build_target_conf(priv, addr, server_pub, server_ip, listen_port, vm_subnet, scope, lan_iface):
	"""
	Generates target (laptop/internal) WireGuard config with:
	- forwarding rules
	- NAT per scope
	- PersistentKeepalive for server peer
	"""
	lines = [
		"[Interface]",
		f"Address = {addr}/24",
		f"PrivateKey = {priv}",
		"ListenPort = 51820",
		"",
		"# Enable IP forwarding",
		"PostUp = sysctl -w net.ipv4.ip_forward=1",
		"PostDown = true",
		"",
		"# Allow forwarding VPN <-> LAN",
		f"PostUp = iptables -I FORWARD 1 -i %i -o {lan_iface} -j ACCEPT",
		f"PostUp = iptables -I FORWARD 1 -i {lan_iface} -o %i -m state --state RELATED,ESTABLISHED -j ACCEPT",
		f"PostDown = iptables -D FORWARD -i %i -o {lan_iface} -j ACCEPT || true",
		f"PostDown = iptables -D FORWARD -i {lan_iface} -o %i -m state --state RELATED,ESTABLISHED -j ACCEPT || true",
	]

	# Add NAT rules per scope
	for s in scope:
		lines.append(f"PostUp = iptables -t nat -A POSTROUTING -s {vm_subnet}/24 -d {s} -o {lan_iface} -j MASQUERADE")
	for s in scope:
		lines.append(f"PostDown = iptables -t nat -D POSTROUTING -s {vm_subnet}/24 -d {s} -o {lan_iface} -j MASQUERADE || true")

	lines += [
		"",
		"[Peer]",
		f"PublicKey = {server_pub}",
		f"Endpoint = {server_ip}:{listen_port}",
		"AllowedIPs = " + ", ".join([f"{vm_subnet}/24"]),
		"PersistentKeepalive = 25",
		""
	]
	return "\n".join(lines)


def build_client_conf(priv, addr, server_pub, server_ip, listen_port, vm_subnet, scope):
	allowed = [f"{vm_subnet}/24"] + scope
	lines = [
		"[Interface]",
		f"Address = {addr}/24",
		f"PrivateKey = {priv}",
		"",
		"[Peer]",
		f"PublicKey = {server_pub}",
		f"Endpoint = {server_ip}:{listen_port}",
		"AllowedIPs = " + ", ".join(allowed),
		"PersistentKeepalive = 25",
		""
	]
	return "\n".join(lines)

def main():
	parser = argparse.ArgumentParser(description="Generate WireGuard project files")
	parser.add_argument("--scope", required=True, help="Path to scope.txt (one CIDR per line)")
	parser.add_argument("--vm-subnet", default="10.200.0.0", help="VM subnet base (default 10.200.0.0)")
	parser.add_argument("--listen-port", default="51820")
	parser.add_argument("--clients", required=True, help="Path to clients.txt (one last-octet per line)")
	parser.add_argument("--target-ip", default=2, help="Target last octet (default 2)")
	parser.add_argument("--server-ip", default="84.44.164.197", help="Public IP of the WireGuard server")
	parser.add_argument("--project", default="anon", help="Output project directory")
	parser.add_argument("--interface", default="eth0", help="LAN interface for NAT (default eth0)")
	args = parser.parse_args()

	# check wg
	try:
		run(["wg", "help"])
	except Exception:
		sys.exit("❌ WireGuard 'wg' tool not found. Install wireguard-tools and re-run.")

	scope = [s.strip() for s in Path(args.scope).read_text().splitlines() if s.strip()]
	clients = [c.strip() for c in Path(args.clients).read_text().splitlines() if c.strip()]

	base_parts = args.vm_subnet.split(".")
	if len(base_parts) != 4:
		sys.exit("vm-subnet must look like: 10.200.0.0")
	net_prefix = ".".join(base_parts[:3])
	server_wg_ip = f"{net_prefix}.1"
	target_wg_ip = f"{net_prefix}.{args.target_ip}"

	project_dir = Path(args.project)
	clients_dir = project_dir / "clients"
	project_dir.mkdir(exist_ok=True)
	clients_dir.mkdir(exist_ok=True)

	print(f"Generating project '{args.project}' ...")
	srv_priv, srv_pub = wg_keypair()
	tgt_priv, tgt_pub = wg_keypair()
	client_rows = []
	for c in clients:
		priv, pub = wg_keypair()
		client_rows.append((c, f"{net_prefix}.{c}", priv, pub))

	# Server peers: target with scope, clients
	peers = []
	peers.append({"name": "target", "pub": tgt_pub, "allowed": [f"{target_wg_ip}/32"] + scope})
	for c, ip, priv, pub in client_rows:
		peers.append({"name": f"client-{c}", "pub": pub, "allowed": [f"{ip}/32"]})

	server_conf = build_server_conf(srv_priv, server_wg_ip, args.listen_port, args.vm_subnet, peers)
	target_conf = build_target_conf(
		tgt_priv, target_wg_ip, srv_pub, args.server_ip, args.listen_port,
		args.vm_subnet, scope, args.interface
	)

	write_file(project_dir / "server.conf", server_conf)
	write_file(project_dir / "target.conf", target_conf)

	for c, ip, priv, pub in client_rows:
		conf = build_client_conf(priv, ip, srv_pub, args.server_ip, args.listen_port, args.vm_subnet, scope)
		write_file(clients_dir / f"client_{c}.conf", conf)

	# README
	readme = textwrap.dedent(f"""\
    Project: {args.project}
    VM subnet: {args.vm_subnet}/24
    Server public IP: {args.server_ip}
    Scope: {', '.join(scope)}
    Clients: {', '.join([r[0] for r in client_rows])}

    Place server.conf on the server at /etc/wireguard/<name>.conf and enable:
      sudo systemctl enable --now wg-quick@<name>

    Target.conf contains PostUp/PostDown hooks for NAT and forwarding (adjust eth0 if needed).
    """)
	(project_dir / "README.txt").write_text(readme)
	(project_dir / "README.txt").chmod(0o644)

	print("Done. Generated files:")
	for p in sorted(project_dir.glob("**/*")):
		print(" -", p.relative_to(project_dir))

if __name__ == "__main__":
	main()

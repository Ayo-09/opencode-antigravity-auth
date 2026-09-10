#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
NOVA GRAVITY AI - download server
Forces Content-Disposition: attachment on binary/config assets so the browser
always offers a real download (works inside the Arena preview iframe too).
Usage:  python3 serve_downloads.py [port]   (default 8787)
"""
import os
import sys
import urllib.parse
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

ROOT = os.path.dirname(os.path.abspath(__file__))
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8787

ATTACH_EXT = {".zip", ".set", ".mq5", ".xlsx", ".csv", ".png", ".txt", ".py", ".json", ".md", ".bmp", ".wav", ".mp3"}


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def guess_type(self, path):
        ext = os.path.splitext(path)[1].lower()
        if ext == ".mq5":
            return "application/octet-stream"
        if ext == ".set":
            return "application/octet-stream"
        if ext == ".xlsx":
            return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        if ext == ".md":
            return "text/markdown; charset=utf-8"
        if ext == ".png":
            return "image/png"
        return super().guess_type(path)

    def end_headers(self):
        path = urllib.parse.urlsplit(self.path).path
        ext = os.path.splitext(path)[1].lower()
        if ext in ATTACH_EXT:
            self.send_header("Content-Disposition", "attachment")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Access-Control-Allow-Origin", "*")
        super().end_headers()

    def log_message(self, *args):  # keep the log small
        pass


if __name__ == "__main__":
    ThreadingHTTPServer.allow_reuse_address = True
    with ThreadingHTTPServer(("0.0.0.0", PORT), Handler) as httpd:
        print("NOVA GRAVITY download server -> http://0.0.0.0:%d  (root: %s)" % (PORT, ROOT), flush=True)
        httpd.serve_forever()

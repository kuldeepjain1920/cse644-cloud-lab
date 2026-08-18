from http.server import BaseHTTPRequestHandler, HTTPServer

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        self.wfile.write(b"Hello from CSE644 Python web server on port 8888\n")

if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 8888), Handler).serve_forever()

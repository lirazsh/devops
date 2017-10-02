from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
import SocketServer
import json

GET_METRICS_PATH = '/metrics'
POST_METRICS_PATH_PREFIX = '/metrics/job/'
METRIC_NAME_FIELD = 'metric'
METRIC_VALUE_FIELD = 'value'
METRIC_TAG_FIELDS = set(['service', 'host', 'dataSource', 'server', 'type'])
CLIENT_ADDRESS_TAG = 'private_ip'

metrics = {}

class S(BaseHTTPRequestHandler):
	def _set_headers(self):
		self.send_response(200)
		self.send_header('Content-type', 'text/plain')
		self.end_headers()

	def do_GET(self):
		if not self.path.startswith(GET_METRICS_PATH):
			self.send_error(400)
			return
		
		self._set_headers()
		body = ''.join(map(lambda p: '%s %s\n' % p, metrics.items()))
		self.wfile.write(body)

	def do_HEAD(self):
		self._set_headers()
		
	@staticmethod
	def getTagValue(value):
		if type(value) == list and len(value) == 1:
			return value[0]
		return value
		
	def do_POST(self):
		global metrics
		
		if not self.path.startswith(POST_METRICS_PATH_PREFIX):
			self.send_error(400)
			return

		metricPrefix = self.path[len(POST_METRICS_PATH_PREFIX):].split('/')[0]
		if len(metricPrefix) > 0:
			metricPrefix += '_'
			
		content_length = int(self.headers['Content-Length'])
		post_data = self.rfile.read(content_length)
		try:
			events = json.loads(post_data)
		except ValueError:
			self.send_error(400)
			return
		
		if type(events) != list:
			self.send_error(400)
			return

		for event in events:
			if type(event) != dict:
				continue

			try:
				metric = metricPrefix + event[METRIC_NAME_FIELD].replace('/', '_')
				value = event[METRIC_VALUE_FIELD]
			except KeyError:
				continue
				
			tags = event.viewkeys() & METRIC_TAG_FIELDS
			tags = map(lambda tag: (tag, self.getTagValue(event[tag])), tags)
			tags.append((CLIENT_ADDRESS_TAG, self.client_address[0]))
			tags = ','.join(map(lambda tag: '%s="%s"' % tag, tags))
			key = '%s{%s}' % (metric, tags)
			metrics[key] = value
				
		self._set_headers()
		self.wfile.write('OK')
		
def run(server_class=HTTPServer, handler_class=S, port=80):
	server_address = ('', port)
	httpd = server_class(server_address, handler_class)
	print 'Starting httpd...'
	httpd.serve_forever()

if __name__ == "__main__":
	from sys import argv

	if len(argv) == 2:
		run(port=int(argv[1]))
	else:
		run()

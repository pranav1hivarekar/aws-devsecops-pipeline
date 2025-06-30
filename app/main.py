from flask import Flask, request, render_template_string
import os
import subprocess
import pickle

app = Flask(__name__)

# Vulnerable: Using an old version of Flask (for SCA)
# Vulnerable: Hard-coded secret key (for SAST)
api_key="hardcoded_secret_key_123"

@app.route('/')
def index():
    return '''
    <h1>Vulnerable Flask App </h1>
    <p><a href="/cmd">Command Execution</a></p>
    <p><a href="/template">Template Injection</a></p>
    <p><a href="/pickle">Pickle Deserialization</a></p>
    '''

# Vulnerable: Command injection (for SAST/DAST)
@app.route('/cmd')
def cmd():
    command = request.args.get('cmd', 'ls')
    try:
        # Vulnerable: Direct command execution without sanitization
        result = subprocess.check_output(command, shell=True, text=True)
        return f'<pre>{result}</pre>'
    except:
        return 'Error executing command'

# Vulnerable: Server-Side Template Injection (for SAST/DAST)
@app.route('/template')
def template():
    name = request.args.get('name', 'World')
    # Vulnerable: Direct template rendering without escaping
    template = f'<h1>Hello {name}!</h1>'
    return render_template_string(template)

# Vulnerable: Pickle deserialization (for SAST)
@app.route('/pickle')
def pickle_demo():
    data = request.args.get('data')
    if data:
        try:
            # Vulnerable: Deserializing untrusted data
            decoded = pickle.loads(data.encode())
            return f'Deserialized: {decoded}'
        except:
            return 'Error deserializing data'
    return 'Provide data parameter'

if __name__ == '__main__':
    # Vulnerable: Debug mode enabled in production (for SAST)
    app.run(host='0.0.0.0', port=5000, debug=False)

from flask import Flask
import os

app = Flask(__name__)

version = os.environ.get('VERSION', 'blue')

@app.route('/')
def index():
    return f"Hello! This is the {version} version of the app."

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
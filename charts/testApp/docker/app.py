from flask import Flask

app = Flask(__name__)

@app.route('/')
def argocd_success():
    return 'Hello All, Welcome to the Jungle'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
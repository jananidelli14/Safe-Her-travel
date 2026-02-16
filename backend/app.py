"""
Safe Her Travel - Backend API
Flask-based REST API for women's safety app
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_socketio import SocketIO, emit
from datetime import datetime
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'your-secret-key-here')
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")

# Import routes
from routes.sos_routes import sos_bp
from routes.chat_routes import chat_bp
from routes.location_routes import location_bp
from routes.resources_routes import resources_bp
from routes.user_routes import user_bp

# Register blueprints
app.register_blueprint(sos_bp, url_prefix='/api/sos')
app.register_blueprint(chat_bp, url_prefix='/api/chat')
app.register_blueprint(location_bp, url_prefix='/api/location')
app.register_blueprint(resources_bp, url_prefix='/api/resources')
app.register_blueprint(user_bp, url_prefix='/api/user')

# WebSocket handlers for real-time tracking
@socketio.on('connect')
def handle_connect():
    print('Client connected')
    emit('connection_response', {'status': 'connected'})

@socketio.on('disconnect')
def handle_disconnect():
    print('Client disconnected')

@socketio.on('location_update')
def handle_location_update(data):
    """Handle real-time location updates"""
    print(f"Location update: {data}")
    # Broadcast to emergency contacts and authorities
    emit('location_broadcast', data, broadcast=True)

@socketio.on('sos_activated')
def handle_sos_activation(data):
    """Handle SOS activation in real-time"""
    print(f"SOS activated: {data}")
    emit('sos_alert', data, broadcast=True)

# Health check endpoint
@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'service': 'Safe Her Travel API'
    }), 200

# Root endpoint
@app.route('/', methods=['GET'])
def root():
    return jsonify({
        'message': 'Safe Her Travel API',
        'version': '1.0.0',
        'endpoints': {
            'sos': '/api/sos',
            'chat': '/api/chat',
            'location': '/api/location',
            'resources': '/api/resources',
            'user': '/api/user'
        }
    }), 200

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
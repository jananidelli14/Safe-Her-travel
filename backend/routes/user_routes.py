"""
User Routes
User authentication, profile, and emergency contacts
"""

from flask import Blueprint, request, jsonify
from datetime import datetime
from database.db import get_db_connection
import uuid
import hashlib

user_bp = Blueprint('user', __name__)

def hash_password(password):
    """Simple password hashing (use bcrypt in production)"""
    return hashlib.sha256(password.encode()).hexdigest()

@user_bp.route('/register', methods=['POST'])
def register():
    """
    Register new user
    Request body: {
        "name": "string",
        "email": "string",
        "phone": "string",
        "password": "string"
    }
    """
    try:
        data = request.json
        user_id = str(uuid.uuid4())
        
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO users (id, name, email, phone, password, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (
            user_id,
            data['name'],
            data['email'],
            data['phone'],
            hash_password(data['password']),
            datetime.now()
        ))
        conn.commit()
        conn.close()
        
        return jsonify({
            'success': True,
            'user_id': user_id,
            'message': 'Registration successful'
        }), 201
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@user_bp.route('/login', methods=['POST'])
def login():
    """User login"""
    try:
        data = request.json
        email = data.get('email')
        password = hash_password(data.get('password'))
        
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT * FROM users
            WHERE email = ? AND password = ?
        """, (email, password))
        
        user = cursor.fetchone()
        conn.close()
        
        if user:
            return jsonify({
                'success': True,
                'user': {
                    'id': user['id'],
                    'name': user['name'],
                    'email': user['email'],
                    'phone': user['phone']
                }
            }), 200
        else:
            return jsonify({
                'success': False,
                'error': 'Invalid credentials'
            }), 401
            
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@user_bp.route('/profile/<user_id>', methods=['GET'])
def get_profile(user_id):
    """Get user profile"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
        user = cursor.fetchone()
        conn.close()
        
        if user:
            user_dict = dict(user)
            del user_dict['password']  # Don't send password
            
            return jsonify({
                'success': True,
                'user': user_dict
            }), 200
        else:
            return jsonify({
                'success': False,
                'error': 'User not found'
            }), 404
            
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@user_bp.route('/emergency-contacts', methods=['POST'])
def add_emergency_contact():
    """
    Add emergency contact
    Request body: {
        "user_id": "string",
        "name": "string",
        "phone": "string",
        "relationship": "string"
    }
    """
    try:
        data = request.json
        contact_id = str(uuid.uuid4())
        
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO emergency_contacts (id, user_id, name, phone, relationship, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (
            contact_id,
            data['user_id'],
            data['name'],
            data['phone'],
            data.get('relationship', 'Emergency Contact'),
            datetime.now()
        ))
        conn.commit()
        conn.close()
        
        return jsonify({
            'success': True,
            'contact_id': contact_id
        }), 201
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@user_bp.route('/emergency-contacts/<user_id>', methods=['GET'])
def get_emergency_contacts(user_id):
    """Get all emergency contacts for a user"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT * FROM emergency_contacts
            WHERE user_id = ?
        """, (user_id,))
        
        contacts = cursor.fetchall()
        conn.close()
        
        return jsonify({
            'success': True,
            'contacts': [dict(c) for c in contacts]
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
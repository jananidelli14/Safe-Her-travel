"""
Enhanced AI Service with Real-Time Data Integration
Chatbot powered by Google Gemini with live emergency services data
"""

import os
import sqlite3
import google.generativeai as genai
from datetime import datetime
from typing import Dict, List, Optional

# Configure Gemini
GEMINI_API_KEY = os.getenv('GEMINI_API_KEY', '')
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    model = genai.GenerativeModel('gemini-pro')
else:
    print("⚠️ Warning: GEMINI_API_KEY not set. Chatbot will use fallback responses.")
    model = None

# Database path
DATABASE_PATH = 'safeher_travel.db'

# Conversation history storage (use Redis in production)
conversation_histories = {}

def get_real_time_context(user_location: Optional[Dict] = None) -> str:
    """
    Fetch real-time data from database to provide context to AI
    
    Args:
        user_location: Dict with 'lat' and 'lng' if available
    
    Returns:
        Context string with real emergency services data
    """
    try:
        conn = sqlite3.connect(DATABASE_PATH)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        context_parts = []
        
        # Get total counts
        cursor.execute("SELECT COUNT(*) as count FROM police_stations")
        police_count = cursor.fetchone()['count']
        
        cursor.execute("SELECT COUNT(*) as count FROM hospitals")
        hospital_count = cursor.fetchone()['count']
        
        context_parts.append(f"Available Emergency Services in Tamil Nadu:")
        context_parts.append(f"- {police_count} Police Stations in database")
        context_parts.append(f"- {hospital_count} Hospitals in database")
        
        # If user location is provided, get nearby services
        if user_location:
            from services.location_service import get_nearest_locations
            
            # Get nearby police stations
            cursor.execute("SELECT * FROM police_stations")
            all_stations = [dict(row) for row in cursor.fetchall()]
            nearby_police = get_nearest_locations(
                user_location['lat'], 
                user_location['lng'], 
                all_stations, 
                limit=3
            )
            
            if nearby_police:
                context_parts.append("\nNearest Police Stations:")
                for i, station in enumerate(nearby_police, 1):
                    context_parts.append(
                        f"{i}. {station['name']} - {station['address']} "
                        f"({station['distance_km']}km away, Phone: {station.get('phone', 'N/A')})"
                    )
            
            # Get nearby hospitals
            cursor.execute("SELECT * FROM hospitals")
            all_hospitals = [dict(row) for row in cursor.fetchall()]
            nearby_hospitals = get_nearest_locations(
                user_location['lat'], 
                user_location['lng'], 
                all_hospitals, 
                limit=3
            )
            
            if nearby_hospitals:
                context_parts.append("\nNearest Hospitals:")
                for i, hospital in enumerate(nearby_hospitals, 1):
                    context_parts.append(
                        f"{i}. {hospital['name']} - {hospital['address']} "
                        f"({hospital['distance_km']}km away, Emergency: {hospital.get('emergency_phone', 'N/A')})"
                    )
        
        conn.close()
        
        return "\n".join(context_parts)
        
    except Exception as e:
        print(f"Error getting real-time context: {e}")
        return ""

ENHANCED_SYSTEM_PROMPT = """You are SafeHer AI, a compassionate and intelligent safety assistant for women travelers in Tamil Nadu, India. Your mission is to keep women safe through immediate, practical, and culturally-aware guidance.

🎯 YOUR CORE RESPONSIBILITIES:
1. Assess danger levels and provide immediate safety guidance
2. Connect users to real emergency services (police, hospitals, safe zones)
3. Offer emotional support during distressing situations
4. Provide location-specific safety advice for Tamil Nadu
5. Help users make safe travel decisions

⚡ EMERGENCY PROTOCOL:
- If user indicates immediate danger: Tell them to call 100 (Police) or 112 (Emergency) NOW
- Advise finding a well-lit, public area with people
- Direct them to use the SOS button in the app
- Provide specific nearby police station/hospital information when available

📞 KEY EMERGENCY NUMBERS:
- Police: 100
- National Emergency: 112
- Ambulance: 108
- Women Helpline: 1091
- Child Helpline: 1098

🌏 TAMIL NADU SPECIFIC KNOWLEDGE:
- Major cities: Chennai, Coimbatore, Madurai, Trichy, Salem
- Tourist spots: Kodaikanal, Ooty, Kanyakumari, Rameswaram, Pondicherry
- Cultural sensitivity: Conservative dress in temples, avoid isolated areas at night
- Language: Tamil is primary, English widely understood in cities
- Transport: Auto-rickshaws (use meter), Trains (women's compartments available), MTC buses in Chennai

🛡️ SAFETY GUIDELINES:
1. Trust your instincts - if it feels wrong, it probably is
2. Stay in well-lit, populated areas
3. Share live location with trusted contacts
4. Use registered transport (Uber, Ola, official taxis)
5. Keep phone charged, have emergency contacts ready
6. Avoid isolated areas, especially at night
7. In temples/tourist spots, be aware of surroundings

💬 COMMUNICATION STYLE:
- Be warm, empathetic, and non-judgmental
- Never minimize or dismiss safety concerns
- Provide clear, actionable steps
- Stay calm even in crisis situations
- Use simple, direct language
- Ask clarifying questions when needed

🚫 NEVER:
- Tell user to "calm down" or "don't worry"
- Blame the victim in any situation
- Provide vague advice without specifics
- Ignore signs of immediate danger
- Share unverified information

When you have access to real-time data about nearby emergency services, USE IT to provide specific, helpful information. Always prioritize user safety above everything else.

Current date and time: {current_time}
"""

def get_ai_response(user_message: str, conversation_id: str, 
                   user_location: Optional[Dict] = None) -> str:
    """
    Get AI response using Gemini with real-time emergency data
    
    Args:
        user_message: User's message
        conversation_id: Unique conversation ID
        user_location: Optional dict with 'lat' and 'lng'
    
    Returns:
        AI response as string
    """
    try:
        if not model:
            return get_intelligent_fallback_response(user_message, user_location)
        
        # Initialize conversation history if needed
        if conversation_id not in conversation_histories:
            conversation_histories[conversation_id] = model.start_chat(history=[])
        
        chat = conversation_histories[conversation_id]
        
        # Build enhanced prompt with real-time context
        current_time = datetime.now().strftime("%B %d, %Y at %I:%M %p")
        system_prompt = ENHANCED_SYSTEM_PROMPT.format(current_time=current_time)
        
        # Get real-time emergency services context
        real_time_context = get_real_time_context(user_location)
        
        # Add system context to first message only
        if len(chat.history) == 0:
            full_message = f"{system_prompt}\n\n{real_time_context}\n\nUser: {user_message}"
        else:
            # For subsequent messages, include location context if available
            if user_location and real_time_context:
                full_message = f"{real_time_context}\n\nUser: {user_message}"
            else:
                full_message = user_message
        
        # Send message and get response
        response = chat.send_message(full_message)
        
        return response.text
        
    except Exception as e:
        print(f"AI Service Error: {e}")
        return get_intelligent_fallback_response(user_message, user_location)

def get_intelligent_fallback_response(message: str, 
                                     user_location: Optional[Dict] = None) -> str:
    """
    Intelligent fallback responses when AI service is unavailable
    Uses keyword matching and database queries
    """
    message_lower = message.lower()
    
    # Emergency/Danger Keywords
    danger_keywords = ['danger', 'unsafe', 'scared', 'help', 'emergency', 'sos', 
                       'threat', 'following', 'harassment', 'attack', 'fear']
    
    if any(word in message_lower for word in danger_keywords):
        response = """🚨 I'm here to help you immediately.

**If you're in immediate danger:**
1. 📞 Call 100 (Police) or 112 (National Emergency) NOW
2. 🏃 Move to a well-lit, crowded area (shop, restaurant, hotel lobby)
3. 🆘 Press the SOS button in the app to alert your contacts
4. 📍 Share your live location with trusted contacts

"""
        # Add nearby police stations if location available
        if user_location:
            nearby_police = get_nearby_police_text(user_location)
            if nearby_police:
                response += f"\n**Nearest Police Stations:**\n{nearby_police}\n"
        
        response += "\nPlease tell me more about your situation so I can help better. What's happening right now?"
        return response
    
    # Police Station Queries
    elif any(word in message_lower for word in ['police', 'station', 'cop', 'officer']):
        if user_location:
            nearby = get_nearby_police_text(user_location)
            if nearby:
                return f"""Here are the nearest police stations to your location:

{nearby}

**Emergency Numbers:**
- Police: 100
- National Emergency: 112

Would you like directions to any of these stations?"""
        
        return """I can help you find nearby police stations. 

**Emergency Police Number: 100**
**National Emergency: 112**

Please share your current location, and I'll find the nearest police stations with their contact numbers and directions."""
    
    # Hospital/Medical Queries
    elif any(word in message_lower for word in ['hospital', 'medical', 'doctor', 'ambulance', 'injured', 'sick']):
        response = """**Medical Emergency:**
📞 Call 108 for Ambulance immediately

"""
        if user_location:
            nearby = get_nearby_hospitals_text(user_location)
            if nearby:
                response += f"**Nearest Hospitals:**\n{nearby}\n"
        else:
            response += "Share your location to find the nearest hospitals.\n"
        
        response += "\nIs this a medical emergency? Do you need an ambulance?"
        return response
    
    # Hotel/Accommodation Queries
    elif any(word in message_lower for word in ['hotel', 'stay', 'accommodation', 'lodge', 'room']):
        return """I can help you find safe accommodations!

**Safety Tips for Hotels:**
✓ Check online reviews, especially from female travelers
✓ Choose well-lit areas with 24/7 security
✓ Prefer hotels near police stations or main roads
✓ Verify the hotel on Google Maps before booking
✓ Share hotel details with family/friends

Share your location, and I'll suggest safe, verified hotels nearby with good reviews."""
    
    # Safety Tips
    elif any(word in message_lower for word in ['tip', 'advice', 'safe', 'how to']):
        return """🛡️ **Essential Safety Tips for Women Travelers in Tamil Nadu:**

**Before Travel:**
✓ Share your itinerary with trusted contacts
✓ Keep phone charged, have power bank
✓ Save emergency numbers: 100 (Police), 108 (Ambulance), 1091 (Women Helpline)

**During Travel:**
✓ Use registered transport (Uber, Ola, official taxis)
✓ Share live location with family/friends
✓ Stay in well-lit, populated areas
✓ Trust your instincts - if uncomfortable, leave

**At Night:**
✓ Avoid isolated areas
✓ Stay in groups when possible
✓ Keep valuables secure
✓ Use hotel transport when available

**In Emergency:**
✓ Call 100 or 112 immediately
✓ Go to nearest public place
✓ Use SOS feature in app

What specific situation would you like safety advice for?"""
    
    # General Greeting/Help
    else:
        return """Hello! I'm SafeHer AI, your personal safety assistant for traveling in Tamil Nadu. 

I can help you with:
🚨 Emergency guidance and immediate help
📍 Finding nearby police stations and hospitals
🏨 Safe accommodation recommendations
🛡️ Safety tips for traveling in Tamil Nadu
💬 Support and advice for any safety concerns

I have real-time access to:
- 35+ Police Stations across Tamil Nadu
- 25+ Hospitals with emergency services
- Safe zones and public places

How can I help keep you safe today?"""

def get_nearby_police_text(location: Dict) -> str:
    """Get formatted text of nearby police stations"""
    try:
        from services.location_service import get_nearest_locations
        
        conn = sqlite3.connect(DATABASE_PATH)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM police_stations")
        all_stations = [dict(row) for row in cursor.fetchall()]
        conn.close()
        
        nearby = get_nearest_locations(location['lat'], location['lng'], all_stations, limit=3)
        
        result = []
        for i, station in enumerate(nearby, 1):
            result.append(
                f"{i}. **{station['name']}**\n"
                f"   📍 {station['address']}\n"
                f"   📞 {station.get('phone', 'N/A')}\n"
                f"   📏 {station['distance_km']} km away"
            )
        
        return "\n\n".join(result)
    except Exception as e:
        print(f"Error getting nearby police: {e}")
        return ""

def get_nearby_hospitals_text(location: Dict) -> str:
    """Get formatted text of nearby hospitals"""
    try:
        from services.location_service import get_nearest_locations
        
        conn = sqlite3.connect(DATABASE_PATH)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM hospitals WHERE is_24x7 = 1")
        all_hospitals = [dict(row) for row in cursor.fetchall()]
        conn.close()
        
        nearby = get_nearest_locations(location['lat'], location['lng'], all_hospitals, limit=3)
        
        result = []
        for i, hospital in enumerate(nearby, 1):
            result.append(
                f"{i}. **{hospital['name']}**\n"
                f"   📍 {hospital['address']}\n"
                f"   🚨 Emergency: {hospital.get('emergency_phone', 'N/A')}\n"
                f"   📏 {hospital['distance_km']} km away\n"
                f"   ⏰ 24/7 Emergency Services"
            )
        
        return "\n\n".join(result)
    except Exception as e:
        print(f"Error getting nearby hospitals: {e}")
        return ""

def clear_conversation(conversation_id: str):
    """Clear conversation history"""
    if conversation_id in conversation_histories:
        del conversation_histories[conversation_id]

def analyze_safety_threat(message: str) -> Dict:
    """
    Analyze message to determine threat level
    
    Returns:
        Dict with threat_level (low/medium/high/critical) and recommended_actions
    """
    message_lower = message.lower()
    
    critical_keywords = ['attack', 'following me', 'grabbed', 'touched', 'assault', 'kidnap']
    high_keywords = ['scared', 'unsafe', 'threatening', 'harassment', 'stalking', 'danger']
    medium_keywords = ['uncomfortable', 'suspicious', 'worried', 'concerned', 'alone']
    
    if any(word in message_lower for word in critical_keywords):
        return {
            'threat_level': 'critical',
            'recommended_actions': ['call_police_immediately', 'activate_sos', 'move_to_public_area']
        }
    elif any(word in message_lower for word in high_keywords):
        return {
            'threat_level': 'high',
            'recommended_actions': ['move_to_safe_location', 'contact_emergency_contacts', 'prepare_to_call_police']
        }
    elif any(word in message_lower for word in medium_keywords):
        return {
            'threat_level': 'medium',
            'recommended_actions': ['stay_alert', 'move_to_populated_area', 'share_location']
        }
    else:
        return {
            'threat_level': 'low',
            'recommended_actions': ['provide_safety_tips', 'offer_assistance']
        }
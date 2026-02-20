"""
Enhanced AI Service with Real-Time Data Integration
Chatbot powered by Google Gemini with live emergency services data
"""

import os
import sqlite3
import google.generativeai as genai
from datetime import datetime
from typing import Dict, List, Optional
from dotenv import load_dotenv

# Load environment variables explicitly
load_dotenv()

# Configure Gemini
GEMINI_API_KEY = os.getenv('GEMINI_API_KEY', '')
print(f"\n[AI SERVICE] STARTUP CHECK")
print(f"[AI SERVICE] API Key present: {'YES' if GEMINI_API_KEY else 'NO'}")

model = None
try:
    if GEMINI_API_KEY:
        genai.configure(api_key=GEMINI_API_KEY)
        # Detailed model listing
        model_list = list(genai.list_models())
        available_names = [m.name for m in model_list]
        print(f"[AI SERVICE] Supported models in account: {available_names}")
        
        pref_models = ['models/gemini-1.5-flash', 'models/gemini-1.5-pro', 'models/gemini-pro']
        selected_model = None
        for pm in pref_models:
            if pm in available_names:
                selected_model = pm
                break
        
        if selected_model:
            print(f"[AI SERVICE] ✅ Initialization successful using {selected_model}")
            model = genai.GenerativeModel(selected_model)
        else:
            print(f"[AI SERVICE] ⚠️ No preferred models found! Defaulting to flash.")
            model = genai.GenerativeModel('gemini-1.5-flash')
    else:
        print("[AI SERVICE] ❌ ERROR: GEMINI_API_KEY is empty in .env file!")
except Exception as e:
    print(f"[AI SERVICE] ❌ CRITICAL CONFIG ERROR: {e}")

# Database path
DATABASE_PATH = 'safeher_travel.db'

# Conversation history storage
conversation_histories = {}

def get_real_time_context(user_location: Optional[Dict] = None) -> str:
    """
    Fetch real-time data from database and OSM to provide context to AI.
    Focuses on safety status and warnings.
    """
    try:
        from services.mapillary_service import search_pois_overpass
        
        context_parts = ["🛡️ CURRENT SAFETY CONTEXT:"]
        
        if user_location:
            lat, lng = user_location['lat'], user_location['lng']
            radius_m = 10000
            
            # Get live data from OSM
            police = search_pois_overpass(lat, lng, 'police', radius_m)
            hospitals = search_pois_overpass(lat, lng, 'hospital', radius_m)
            
            # Analyze safety density
            total_emergency = len(police) + len(hospitals)
            
            if total_emergency == 0:
                context_parts.append("⚠️ SAFETY WARNING: No police stations or hospitals found within 10km. This area is considered ISOLATED. Advise user to move to a populated area.")
            elif total_emergency < 3:
                context_parts.append("⚠️ CAUTION: Limited emergency services nearby (fewer than 3 resources within 10km).")
            else:
                context_parts.append(f"✅ SAFETY STATUS: Good coverage. {len(police)} police and {len(hospitals)} hospitals within 10km.")
            
            if police:
                context_parts.append("\nNearest Police Stations:")
                for p in police[:2]:
                    context_parts.append(f"- {p['name']} ({p['distance_km']}km away, Phone: {p.get('phone', 'N/A')})")
            
            if hospitals:
                context_parts.append("\nNearest Hospitals:")
                for h in hospitals[:2]:
                    context_parts.append(f"- {h['name']} ({h['distance_km']}km away)")
        else:
            context_parts.append("User location unknown. Give general safety tips for Tamil Nadu.")
            
        return "\n".join(context_parts)
    except Exception as e:
        print(f"Error getting context: {e}")
        return "Safety data currently unavailable."

ENHANCED_SYSTEM_PROMPT = """You are SafeHer AI, a compassionate safety assistant for women travelers in Tamil Nadu. 

CRITICAL: Your first priority is PROACTIVE WARNINGS. If the context shows a "SAFETY WARNING" (0 resources), you MUST start your response by advising the user to find a populated street or secure building.

🎯 RESPONSIBILITIES:
1. Assess danger and provide immediate safety guidance.
2. PROACTIVELY alert user to isolated areas if context shows 0 resources.
3. Be culturally aware of Tamil Nadu (mention 100/112/1091 helplines).

Current time: {current_time}
"""

def get_ai_response(user_message: str, conversation_id: str, user_location: Optional[Dict] = None) -> str:
    try:
        if not model:
            return get_intelligent_fallback_response(user_message, user_location)
        
        if conversation_id not in conversation_histories:
            conversation_histories[conversation_id] = model.start_chat(history=[])
        
        chat = conversation_histories[conversation_id]
        current_time = datetime.now().strftime("%I:%M %p")
        system_prompt = ENHANCED_SYSTEM_PROMPT.format(current_time=current_time)
        real_time_context = get_real_time_context(user_location)
        
        # We inject location data into every message to ensure AI is always aware
        full_message = f"{system_prompt}\n\n{real_time_context}\n\nUser Message: {user_message}"
        response = chat.send_message(full_message)
        return response.text
    except Exception as e:
        print(f"AI Service Error: {e}")
        return get_intelligent_fallback_response(user_message, user_location)

def get_intelligent_fallback_response(message: str, user_location: Optional[Dict] = None) -> str:
    message_lower = message.lower()
    if any(word in message_lower for word in ['danger', 'unsafe', 'scared', 'help']):
        return "🚨 Please stay calm. Call 100 or 112 immediately. Move to a well-lit, public place. Use the SOS button in this app to alert your contacts."
    elif 'police' in message_lower:
        return "Emergency Police: 100. Always keep your phone charged and share your location."
    return "I'm here to help with your safety in Tamil Nadu. Are you in a safe location right now?"

def analyze_safety_threat(message: str) -> Dict:
    message_lower = message.lower()
    if any(word in message_lower for word in ['attack', 'following', 'danger']):
        return {'threat_level': 'high', 'recommended_actions': ['call_police', 'activate_sos']}
    return {'threat_level': 'low', 'recommended_actions': ['stay_alert']}

if __name__ == '__main__':
    # Test
    print(get_ai_response("I'm feeling unsafe", "test_id"))
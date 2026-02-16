"""
Notification Service
SMS and Email notifications using Twilio and SendGrid
"""

import os
from twilio.rest import Client
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail

# Twilio configuration
TWILIO_ACCOUNT_SID = os.getenv('TWILIO_ACCOUNT_SID')
TWILIO_AUTH_TOKEN = os.getenv('TWILIO_AUTH_TOKEN')
TWILIO_PHONE_NUMBER = os.getenv('TWILIO_PHONE_NUMBER')

# SendGrid configuration
SENDGRID_API_KEY = os.getenv('SENDGRID_API_KEY')
FROM_EMAIL = os.getenv('FROM_EMAIL', 'noreply@safehertravel.com')

def send_sms(to_phone, message):
    """
    Send SMS using Twilio
    
    Args:
        to_phone: Recipient phone number (with country code)
        message: SMS message content
    
    Returns:
        bool: Success status
    """
    try:
        if not TWILIO_ACCOUNT_SID or not TWILIO_AUTH_TOKEN:
            print(f"[SMS SIMULATION] To: {to_phone}")
            print(f"[SMS SIMULATION] Message: {message}")
            return True
        
        client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
        
        message = client.messages.create(
            body=message,
            from_=TWILIO_PHONE_NUMBER,
            to=to_phone
        )
        
        print(f"SMS sent successfully: {message.sid}")
        return True
        
    except Exception as e:
        print(f"SMS sending failed: {e}")
        return False

def send_email(to_email, subject, content):
    """
    Send email using SendGrid
    
    Args:
        to_email: Recipient email address
        subject: Email subject
        content: Email body (HTML or plain text)
    
    Returns:
        bool: Success status
    """
    try:
        if not SENDGRID_API_KEY:
            print(f"[EMAIL SIMULATION] To: {to_email}")
            print(f"[EMAIL SIMULATION] Subject: {subject}")
            print(f"[EMAIL SIMULATION] Content: {content}")
            return True
        
        message = Mail(
            from_email=FROM_EMAIL,
            to_emails=to_email,
            subject=subject,
            html_content=content
        )
        
        sg = SendGridAPIClient(SENDGRID_API_KEY)
        response = sg.send(message)
        
        print(f"Email sent successfully: {response.status_code}")
        return True
        
    except Exception as e:
        print(f"Email sending failed: {e}")
        return False

def send_sos_alert_sms(phone, user_name, location):
    """Send SOS alert SMS to emergency contact"""
    message = f"""🚨 EMERGENCY ALERT - Safe Her Travel

{user_name} has activated an SOS alert!

Location: https://maps.google.com/?q={location['lat']},{location['lng']}

This is an automated emergency notification. Please contact them immediately or call emergency services.

Emergency Numbers:
- Police: 100
- Ambulance: 108
- National Emergency: 112"""
    
    return send_sms(phone, message)

def send_sos_alert_email(email, user_name, location):
    """Send SOS alert email to emergency contact"""
    subject = f"🚨 EMERGENCY: {user_name} needs help"
    
    content = f"""
    <html>
        <body style="font-family: Arial, sans-serif; padding: 20px;">
            <div style="background-color: #ff4757; color: white; padding: 20px; border-radius: 10px;">
                <h1>🚨 EMERGENCY ALERT</h1>
            </div>
            
            <div style="padding: 20px;">
                <p><strong>{user_name}</strong> has activated an SOS emergency alert through Safe Her Travel app.</p>
                
                <h2>Current Location:</h2>
                <p>
                    Latitude: {location['lat']}<br>
                    Longitude: {location['lng']}<br>
                    <a href="https://maps.google.com/?q={location['lat']},{location['lng']}" 
                       style="background-color: #5DCCF7; color: white; padding: 10px 20px; 
                              text-decoration: none; border-radius: 5px; display: inline-block; margin-top: 10px;">
                        View on Google Maps
                    </a>
                </p>
                
                <h2>What to do:</h2>
                <ol>
                    <li>Try to contact {user_name} immediately</li>
                    <li>If you cannot reach them, call emergency services</li>
                    <li>Share the location with local authorities if needed</li>
                </ol>
                
                <h3>Emergency Numbers (Tamil Nadu):</h3>
                <ul>
                    <li>Police: 100</li>
                    <li>Ambulance: 108</li>
                    <li>National Emergency: 112</li>
                    <li>Women Helpline: 1091</li>
                </ul>
            </div>
            
            <div style="background-color: #f5f5f5; padding: 15px; margin-top: 20px; border-radius: 5px;">
                <p style="margin: 0; font-size: 12px; color: #666;">
                    This is an automated emergency notification from Safe Her Travel.
                </p>
            </div>
        </body>
    </html>
    """
    
    return send_email(email, subject, content)

def send_location_share_notification(phone, user_name, share_link):
    """Send location sharing notification"""
    message = f"""{user_name} is sharing their live location with you via Safe Her Travel.

Track their location here: {share_link}

This link will remain active for the specified duration."""
    
    return send_sms(phone, message)
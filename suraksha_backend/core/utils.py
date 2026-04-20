import os
from datetime import datetime
import pytz
from PIL import Image, ImageDraw, ImageFont
from django.conf import settings

def add_timestamp_to_image(image_field):
    """
    Adds a red IST timestamp to the bottom right of the image.
    image_field: Django ImageField or similar file-like object.
    """
    # Open the image
    img = Image.open(image_field)
    draw = ImageDraw.Draw(img)
    
    # Configure IST Time
    ist = pytz.timezone('Asia/Kolkata')
    timestamp = datetime.now(ist).strftime("%Y-%m-%d %H:%M:%S IST")
    
    # Choose a font size (approx 5% of image height)
    width, height = img.size
    font_size = max(10, int(height * 0.05))
    
    # Try to load a font, fallback to default
    try:
        # On Windows/Linux systems, usually some font is available. 
        # Using a basic path for robustness if possible, but default is safer.
        font = ImageFont.load_default()
    except Exception:
        font = ImageFont.load_default()
        
    # Position: Bottom Right
    # Use textbbox if available in newer Pillow, else textsize
    if hasattr(draw, 'textbbox'):
        bbox = draw.textbbox((0, 0), timestamp, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
    else:
        text_width, text_height = draw.textsize(timestamp, font=font)
        
    margin = 10
    x = width - text_width - margin
    y = height - text_height - margin
    
    # Draw a small shadow/outline for readability
    draw.text((x+1, y+1), timestamp, fill="black", font=font)
    draw.text((x, y), timestamp, fill="red", font=font)
    
    return img

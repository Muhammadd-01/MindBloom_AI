"""
AI-Based Positive Attitude Creator - FastAPI Backend
NLP-powered sentiment analysis, tone detection, and smart feedback engine
With Supabase Storage integration for image uploads
"""

import os
import uuid
from datetime import datetime
from typing import List, Optional

from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import google.generativeai as genai
from dotenv import load_dotenv

# Load .env
load_dotenv()

try:
    from supabase import create_client, Client
    SUPABASE_AVAILABLE = True
except ImportError:
    SUPABASE_AVAILABLE = False

# ── Environment Configuration ──
# Load from .env or environment variables
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")

# Initialize Gemini
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    model = genai.GenerativeModel('gemini-1.5-flash') # Using flash for lower latency in voice/chat
else:
    model = None

# Initialize Supabase client (server-side with service_role key)
supabase: Optional[Client] = None
if SUPABASE_AVAILABLE and SUPABASE_URL and SUPABASE_SERVICE_KEY:
    supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

# ── Models ──

class AnalyzeRequest(BaseModel):
    text: str
    user_id: str
    input_type: str = "journal"  # 'journal', 'voice', 'mood'

class AnalyzeResponse(BaseModel):
    id: str
    userId: str
    inputText: str
    inputType: str
    positivityScore: int
    sentiment: str
    tone: str
    keywords: List[str]
    analyzedAt: str

class FeedbackRequest(BaseModel):
    sentiment: str
    tone: str
    score: int

class FeedbackItem(BaseModel):
    type: str
    title: str
    description: str
    quran_verse: Optional[str] = None
    hadith: Optional[str] = None
    icon: str = "💡"

class ChatRequest(BaseModel):
    message: str
    context: Optional[str] = None

class ChatResponse(BaseModel):
    response: str

class UploadResponse(BaseModel):
    url: str
    bucket: str
    path: str

# ── App Setup ──

app = FastAPI(
    title="Positive Attitude Creator API",
    description="AI-powered sentiment analysis and positivity coaching",
    version="1.0.0",
)

# CORS — allow Flutter app to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── NLP Analysis Service ──

# Keyword dictionaries for sentiment analysis
POSITIVE_WORDS = {
    'happy', 'great', 'good', 'love', 'wonderful', 'amazing', 'blessed',
    'grateful', 'excited', 'joy', 'peace', 'thank', 'beautiful', 'hope',
    'positive', 'awesome', 'fantastic', 'excellent', 'smile', 'kind',
    'alhamdulillah', 'mashallah', 'inshallah', 'succeed', 'strong',
    'proud', 'accomplish', 'calm', 'relax', 'inspire', 'motivate',
    'confidence', 'growth', 'progress', 'learn', 'improve', 'faith',
}

NEGATIVE_WORDS = {
    'sad', 'bad', 'angry', 'hate', 'terrible', 'awful', 'stressed',
    'anxious', 'depressed', 'worried', 'fear', 'pain', 'sick', 'tired',
    'frustrated', 'upset', 'annoyed', 'lonely', 'worst', 'cry',
    'fail', 'hopeless', 'doubt', 'regret', 'guilt', 'ashamed',
    'overwhelmed', 'exhausted', 'disappointed', 'confused',
}

TONE_INDICATORS = {
    'calm': ['peaceful', 'calm', 'relax', 'serene', 'gentle', 'quiet'],
    'stress': ['stressed', 'overwhelmed', 'pressure', 'deadline', 'rush', 'hectic'],
    'anger': ['angry', 'furious', 'mad', 'rage', 'annoyed', 'irritated'],
    'motivation': ['motivated', 'driven', 'goal', 'achieve', 'succeed', 'hustle'],
    'joy': ['happy', 'joyful', 'excited', 'thrilled', 'elated', 'celebrate'],
    'sadness': ['sad', 'cry', 'lonely', 'depressed', 'melancholy', 'grief'],
}


def analyze_text(text: str) -> dict:
    """Perform sentiment analysis, tone detection, and score calculation"""
    lower_text = text.lower()
    words = lower_text.split()
    
    # Count positive and negative word matches
    positive_count = sum(1 for w in words if w.strip('.,!?;:') in POSITIVE_WORDS)
    negative_count = sum(1 for w in words if w.strip('.,!?;:') in NEGATIVE_WORDS)
    
    # Extract keywords
    keywords = [w for w in words if w.strip('.,!?;:') in (POSITIVE_WORDS | NEGATIVE_WORDS)]
    keywords = list(set(keywords))[:5]
    
    # Calculate sentiment
    if positive_count > negative_count:
        sentiment = "positive"
        score = min(60 + (positive_count * 8), 98)
    elif negative_count > positive_count:
        sentiment = "negative" 
        score = max(40 - (negative_count * 8), 5)
    else:
        sentiment = "neutral"
        score = 50
    
    # Detect tone
    tone = "calm"
    max_tone_score = 0
    for tone_name, indicators in TONE_INDICATORS.items():
        tone_score = sum(1 for ind in indicators if ind in lower_text)
        if tone_score > max_tone_score:
            max_tone_score = tone_score
            tone = tone_name
    
    return {
        "positivityScore": score,
        "sentiment": sentiment,
        "tone": tone,
        "keywords": keywords,
    }


# ── Feedback Engine ──

NEGATIVE_FEEDBACK = [
    FeedbackItem(
        type="breathing",
        title="Deep Breathing Exercise",
        description="Take 5 deep breaths. Inhale for 4 seconds, hold for 7, exhale for 8. This activates your parasympathetic nervous system.",
        icon="🧘",
    ),
    FeedbackItem(
        type="reflection",
        title="Gratitude Reflection",
        description="Write down 3 things you are grateful for today. Gratitude shifts focus from what's lacking to what's abundant.",
        icon="📝",
    ),
    FeedbackItem(
        type="islamic",
        title="Quranic Comfort",
        description="Remember Allah's words of comfort and hope.",
        quran_verse='"Verily, with hardship, there is relief." — Quran 94:6',
        hadith='"No fatigue, nor disease, nor sorrow, nor sadness, nor hurt, nor distress befalls a Muslim, even if it were the prick he receives from a thorn, but that Allah expiates some of his sins for that." — Bukhari',
        icon="🕌",
    ),
]

POSITIVE_FEEDBACK = [
    FeedbackItem(
        type="habit",
        title="Keep It Up!",
        description="Your positivity is shining! Share your positive energy with someone today.",
        icon="⭐",
    ),
    FeedbackItem(
        type="habit",
        title="Gratitude Boost",
        description="You're doing great! Consider journaling what made today special.",
        icon="🌟",
    ),
    FeedbackItem(
        type="islamic",
        title="Islamic Wisdom",
        description="Continue in gratitude and remembrance.",
        quran_verse='"If you are grateful, I will surely increase your favor." — Quran 14:7',
        icon="🕌",
    ),
]


# ── API Endpoints ──

@app.get("/")
async def root():
    """Health check endpoint"""
    return {"status": "running", "service": "Positive Attitude Creator API", "version": "1.0.0"}


@app.post("/analyze", response_model=AnalyzeResponse)
async def analyze(request: AnalyzeRequest):
    """Analyze user text input for sentiment, tone, and positivity score"""
    if not request.text.strip():
        raise HTTPException(status_code=400, detail="Text input is required")
    
    analysis = analyze_text(request.text)
    
    return AnalyzeResponse(
        id=str(uuid.uuid4()),
        userId=request.user_id,
        inputText=request.text,
        inputType=request.input_type,
        positivityScore=analysis["positivityScore"],
        sentiment=analysis["sentiment"],
        tone=analysis["tone"],
        keywords=analysis["keywords"],
        analyzedAt=datetime.now().isoformat(),
    )


@app.post("/feedback", response_model=List[FeedbackItem])
async def get_feedback(request: FeedbackRequest):
    """Get smart feedback based on analysis results"""
    if request.sentiment == "negative" or request.score < 40:
        return NEGATIVE_FEEDBACK
    return POSITIVE_FEEDBACK


@app.post("/chatbot", response_model=ChatResponse)
async def chatbot(request: ChatRequest):
    """AI positivity coach chatbot powered by Gemini Pro"""
    if not model:
        return ChatResponse(response="I'm currently in offline mode. How can I help you locally?")
    
    msg = request.message
    psych_context = request.context or "No specific psychological history provided."
    
    system_prompt = f"""
    You are the 'MindBloom AI Coach', a world-class clinical behavioral psychologist and mindfulness expert.
    Your mission is to help the user cultivate a positive attitude, build resilience, and process emotions using CBT (Cognitive Behavioral Therapy), DBT (Dialectical Behavior Therapy), and ACT (Acceptance and Commitment Therapy).

    USER CONTEXT:
    {psych_context}

    INSTRUCTIONS:
    1. Tone: Empathetic, professional, warm, and highly insightful.
    2. Framework: Use CBT to identify distortions, DBT for emotional regulation, and Rogerian empathy.
    3. Formatting: Use clear, concise paragraphs. Use emojis sparingly for warmth.
    4. Safety: If you detect a crisis (suicide, self-harm), provide immediate compassionate grounding and urge them to seek professional human help.
    5. Islamic Context (If relevant): If the user mentions faith or Islamic concepts, incorporate supportive Quranic/Hadith wisdom (like Sabr, Shukr, Tawakkul) naturally.
    
    Current Message: "{msg}"
    """
    
    try:
        response = model.generate_content(system_prompt)
        return ChatResponse(response=response.text)
    except Exception as e:
        # Fallback to local logic if Gemini fails
        return ChatResponse(response="I'm processing a lot of thoughts right now. Take a deep breath with me. What else is on your mind?")


# ── Image Upload Endpoints (Supabase Storage) ──

@app.post("/upload-image", response_model=UploadResponse)
async def upload_image(
    file: UploadFile = File(...),
    user_id: str = Form(...),
    bucket: str = Form(default="journal-attachments"),  # or 'profile-images'
):
    """
    Upload an image to Supabase Storage and return the public URL.
    The URL can then be stored in Firestore by the Flutter app.
    
    Buckets:
    - 'profile-images': for user profile pictures
    - 'journal-attachments': for journal entry images
    """
    if not supabase:
        raise HTTPException(
            status_code=503,
            detail="Supabase Storage is not configured. Set SUPABASE_URL and SUPABASE_SERVICE_KEY."
        )
    
    # Validate bucket name
    if bucket not in ('profile-images', 'journal-attachments'):
        raise HTTPException(status_code=400, detail="Invalid bucket. Use 'profile-images' or 'journal-attachments'.")
    
    # Validate file type
    allowed_types = {'image/jpeg', 'image/png', 'image/webp', 'image/gif'}
    if file.content_type not in allowed_types:
        raise HTTPException(status_code=400, detail=f"Invalid file type: {file.content_type}. Allowed: {allowed_types}")
    
    # Validate file size (max 10MB)
    contents = await file.read()
    max_size = 10 * 1024 * 1024  # 10 MB
    if len(contents) > max_size:
        raise HTTPException(status_code=400, detail=f"File too large. Max size: 10MB")
    
    # Generate unique file path: {user_id}/{uuid}.{ext}
    ext = file.filename.split('.')[-1] if file.filename and '.' in file.filename else 'jpg'
    file_path = f"{user_id}/{uuid.uuid4()}.{ext}"
    
    try:
        # Upload to Supabase Storage
        result = supabase.storage.from_(bucket).upload(
            path=file_path,
            file=contents,
            file_options={"content-type": file.content_type}
        )
        
        # Get public URL
        public_url = supabase.storage.from_(bucket).get_public_url(file_path)
        
        return UploadResponse(
            url=public_url,
            bucket=bucket,
            path=file_path,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")


@app.delete("/delete-image")
async def delete_image(
    bucket: str = Form(...),
    path: str = Form(...),
    user_id: str = Form(...),
):
    """
    Delete an image from Supabase Storage.
    Only allows deletion from the user's own folder.
    """
    if not supabase:
        raise HTTPException(status_code=503, detail="Supabase Storage not configured.")
    
    # Security: ensure the path starts with the user's ID
    if not path.startswith(f"{user_id}/"):
        raise HTTPException(status_code=403, detail="Cannot delete files from another user's folder.")
    
    try:
        supabase.storage.from_(bucket).remove([path])
        return {"status": "deleted", "path": path}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Delete failed: {str(e)}")


# ── Run with: uvicorn main:app --reload --host 0.0.0.0 --port 8000 ──

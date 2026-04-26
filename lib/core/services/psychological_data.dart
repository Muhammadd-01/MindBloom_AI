/// A comprehensive psychological knowledge base containing NLP rules,
/// cognitive distortions, DBT techniques, and Rogerian response frameworks.
class PsychologicalData {
  // ── 1. COGNITIVE BEHAVIORAL THERAPY (CBT) DISTORTIONS ──
  
  static const Map<String, List<String>> cognitiveDistortions = {
    'All-or-Nothing Thinking': [
      'always', 'never', 'every time', 'impossible', 'perfect', 'failure',
      'ruined everything', 'complete disaster'
    ],
    'Overgeneralization': [
      'everyone', 'nobody', 'all the time', 'nothing good', 'typical',
    ],
    'Mental Filter': [
      'but', 'only bad', 'doesn\'t matter', 'ignore the good',
    ],
    'Mind Reading': [
      'they think', 'they hate me', 'he thinks', 'she thinks', 'know what they',
      'judging me'
    ],
    'Catastrophizing': [
      'end of the world', 'terrible', 'horrible', 'worst possible', 'disaster',
      'i will die if', 'can\'t survive'
    ],
    'Should Statements': [
      'i should', 'i must', 'i have to', 'they should', 'ought to',
    ],
    'Personalization': [
      'my fault', 'because of me', 'i am to blame', 'all me',
    ],
  };

  static const Map<String, String> cbtInterventions = {
    'All-or-Nothing Thinking': 'I notice you are using absolute words like "always" or "never". Reality is rarely black and white. Can we find a shade of gray in this situation?',
    'Overgeneralization': 'You might be taking one negative event and seeing it as a never-ending pattern of defeat. What is one piece of evidence that contradicts this?',
    'Mental Filter': 'It sounds like you are filtering out the positive aspects of the situation. Can you name one good thing that happened today, no matter how small?',
    'Mind Reading': 'You are assuming you know what others are thinking. Do you have concrete, undeniable proof that they are judging you, or is this anxiety speaking?',
    'Catastrophizing': 'Your mind is jumping to the worst possible outcome. Let\'s pause. What is the most realistic outcome, rather than the most disastrous one?',
    'Should Statements': 'You are putting a lot of pressure on yourself with "shoulds". Try replacing "I should" with "It would be nice if I could". How does that feel?',
    'Personalization': 'You are taking the blame for something that isn\'t entirely in your control. What external factors also contributed to this situation?',
  };

  // ── 2. DIALECTICAL BEHAVIOR THERAPY (DBT) ──
  
  static const Map<String, List<String>> emotionalDysregulation = {
    'High Distress': ['can\'t take it', 'freaking out', 'losing my mind', 'explode', 'overwhelmed'],
    'Self-Harm Urges': ['hurt myself', 'cut myself', 'punish myself', 'deserve pain'],
    'Dissociation': ['numb', 'unreal', 'not here', 'out of body', 'floating', 'zombie'],
    'Interpersonal Conflict': ['screamed at', 'fight with', 'argument', 'breakup', 'hate them'],
  };

  static const Map<String, String> dbtSkills = {
    'High Distress': 'DBT Skill (TIPP): Your nervous system is overloaded. Go splash ice-cold water on your face for 30 seconds. This triggers the mammalian dive reflex and forces your heart rate to slow down.',
    'Self-Harm Urges': 'DBT Skill (Distress Tolerance): I hear how much pain you are in. Before acting on this urge, try holding an ice cube tightly until it melts, or snap a rubber band on your wrist. Give yourself 15 minutes to ride the wave.',
    'Dissociation': 'DBT Skill (5-4-3-2-1 Grounding): You are safe, but your mind is drifting. Name 5 things you can see right now. Touch 4 things around you. Listen for 3 sounds. Ground yourself back into this exact room.',
    'Interpersonal Conflict': 'DBT Skill (DEAR MAN): When emotions are this high, communication breaks down. Step away from the argument. Use "I feel" statements instead of "You always" statements when you return.',
  };

  // ── 3. PLUTCHIK'S WHEEL OF EMOTIONS (Advanced Sentiment) ──

  static const Map<String, List<String>> advancedEmotions = {
    'Ecstasy/Joy': ['thrilled', 'ecstatic', 'blessed', 'overjoyed', 'amazing', 'perfect', 'love'],
    'Vigilance/Anticipation': ['waiting', 'expecting', 'ready', 'looking forward', 'excited'],
    'Rage/Anger': ['furious', 'rage', 'hate', 'livid', 'pissed', 'angry', 'mad'],
    'Loathing/Disgust': ['gross', 'sick', 'disgusting', 'repulsive', 'hate myself', 'ugly'],
    'Grief/Sadness': ['devastated', 'heartbroken', 'hopeless', 'depressed', 'grief', 'empty'],
    'Terror/Fear': ['terrified', 'panic', 'scared', 'fear', 'dread', 'nightmare'],
    'Amazement/Surprise': ['shocked', 'speechless', 'wow', 'unexpected', 'stunned'],
    'Admiration/Trust': ['trust', 'safe', 'secure', 'admire', 'respect', 'supported'],
  };

  // ── 4. ROGERIAN EMPATHY FRAMEWORKS ──

  static const List<String> rogerianReflections = [
    'I hear how deeply this is affecting you.',
    'Thank you for trusting me with these thoughts.',
    'It takes a lot of courage to admit that.',
    'It sounds like you are carrying an incredibly heavy burden right now.',
    'I am listening, and your feelings are completely valid.',
    'That must be exhausting for you to process.',
  ];

  static const List<String> activeListeningProbes = [
    'Can you tell me more about what triggered this feeling?',
    'How does your body physically feel when you think about this?',
    'What is the hardest part about this situation for you?',
    'If you could talk to yourself as a kind friend right now, what would you say?',
  ];
}

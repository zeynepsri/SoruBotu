from flask import Flask, request, jsonify
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import nltk
from nltk.corpus import stopwords
import string
import re
from flask_cors import CORS

nltk.download('stopwords')

app = Flask(__name__)
CORS(app)

# Veriseti dosyasını oku (csv; sütunlar: soru, cevap)
data = pd.read_csv('veriseti.csv', delimiter=';')

questions = data['soru'].astype(str).tolist()
answers = data['cevap'].astype(str).tolist()

def preprocess(text):
    text = text.lower()
    text = re.sub(r'\d+', '', text)  # Sayıları çıkar
    text = text.translate(str.maketrans('', '', string.punctuation))  # Noktalama işaretlerini çıkar
    text = text.strip()
    words = text.split()
    stop_words = set(stopwords.words('turkish'))
    filtered = [word for word in words if word not in stop_words]
    return ' '.join(filtered)

processed_questions = [preprocess(q) for q in questions]

vectorizer = TfidfVectorizer()
question_vectors = vectorizer.fit_transform(processed_questions)

@app.route('/soru', methods=['POST'])
def cevapla():
    user_input = request.json.get('soru', '')
    if not user_input:
        return jsonify({'hata': 'Soru boş olamaz.'}), 400

    processed_input = preprocess(user_input)
    input_vector = vectorizer.transform([processed_input])

    similarities = cosine_similarity(input_vector, question_vectors)
    max_score = similarities.max()

    threshold = 0.3
    if max_score < threshold:
        input_words = set(processed_input.split())
        
        max_common_words = 0
        best_idx = -1
        
        for i, q in enumerate(processed_questions):
            q_words = set(q.split())
            common_words = len(input_words.intersection(q_words))
            if common_words > max_common_words:
                max_common_words = common_words
                best_idx = i

        if best_idx == -1 or max_common_words == 0:
            return jsonify({'cevap': 'Üzgünüm, sorunuzu anlayamadım. Lütfen daha açık bir şekilde sorun.'})

        return jsonify({'cevap': answers[best_idx]})

    closest_idx = similarities.argmax()
    return jsonify({'cevap': answers[closest_idx]})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)

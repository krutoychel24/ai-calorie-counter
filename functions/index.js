// functions/index.js

const { onRequest } = require("firebase-functions/v2/https");
const { GoogleGenerativeAI } = require('@google/generative-ai');
const cors = require("cors")({ origin: true });

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

exports.analyzeImage = onRequest(
  {
    secrets: ['GEMINI_API_KEY'],
    cors: true,
    timeoutSeconds: 60,
    memory: '512MiB' // Память для gemini-2.5-flash
  },
  (req, res) => {
    cors(req, res, async () => {

      if (req.method !== "POST") {
        console.warn(`Received ${req.method} request, expected POST.`);
        return res.status(405).json({ error: "Method Not Allowed" });
      }

      try {
        // Допускаем данные как в req.body.data, так и напрямую в req.body
        const { imageBase64, mimeType, languageCode = 'en' } = req.body.data || req.body;

        if (!imageBase64 || !mimeType) {
          console.error("Missing imageBase64 or mimeType in request body.");
          return res.status(400).json({ error: "Missing imageBase64 or mimeType" });
        }

        console.log('Request received. Language:', languageCode, 'Image size:', imageBase64.length, 'chars. MIME type:', mimeType);

        const model = genAI.getGenerativeModel({
          model: "gemini-2.5-flash" // Using gemini-2.5-flash as requested
        });
        console.log('Using model: gemini-2.5-flash');

        // --- NEW MULTI-LANGUAGE PROMPT ---
        const prompt = `
As an expert nutritionist, analyze the food image provided.

Your response MUST be a single, valid JSON object, without any markdown formatting, backticks, or other non-JSON text.

Based on the user's language code "${languageCode}", the "dish_name" must be in that language.

JSON structure required:
{
  "dish_name": "[name of the dish in the specified language]",
  "weight": [number, in grams],
  "calories": [number],
  "protein": [number, in grams],
  "fat": [number, in grams],
  "carbs": [number, in grams],
  "ingredients": ["ingredient1", "ingredient2"],
  "usefulness": [a score from 0 to 10 representing the health benefit of this food]
}
`;
        // --- END OF NEW PROMPT ---

        const imagePart = {
          inlineData: { data: imageBase64, mimeType: mimeType }
        };

        console.log('Sending request to Gemini API...');

        const result = await model.generateContent([prompt, imagePart]);
        const response = await result.response;

        // Простая проверка ответа
        if (!response?.candidates?.[0]?.content?.parts?.[0]?.text) {
             console.error("Gemini API returned an empty or invalid response structure:", JSON.stringify(response));
             return res.status(500).json({ error: "Internal Server Error", details: "Received invalid response structure from AI." });
        }

        const text = response.text();
        console.log('Response text from Gemini (start):', text.substring(0, 300) + '...');

        // Простая очистка от markdown
        let jsonText = text
          .replace(/```json/g, "")
          .replace(/```/g, "")
          .trim();

        // Попытка найти JSON блок, если очистка не помогла
        const jsonMatch = jsonText.match(/\{[\s\S]*\}/);
        if (jsonMatch && jsonMatch[0].length > 10) {
            jsonText = jsonMatch[0];
            console.log('Extracted JSON block using regex.');
        } else {
             console.warn('Could not reliably extract JSON block using regex, proceeding with trimmed text.');
        }

        console.log('Cleaned JSON attempt (start):', jsonText.substring(0, 300) + '...');

        // Парсинг JSON
        try {
           const parsedData = JSON.parse(jsonText);
           console.log('JSON parsed successfully.');
           return res.status(200).json(parsedData); // Отправляем успешный ответ

        } catch (parseError) {
             console.error("Error parsing JSON:", parseError);
             console.error("Original text received:", text);
             console.error("Attempted cleaned text:", jsonText);
             return res.status(500).json({
                error: "Internal Server Error",
                details: "Failed to parse JSON response from AI.",
                raw_response: text // Можно передать сырой ответ для отладки на клиенте
             });
        }

      } catch (error) {
        // Обработка остальных ошибок
        console.error("Error processing request:", error);
        if (error.response) {
            console.error("API Response Status:", error.response.status);
            console.error("API Response Data:", error.response.data);
        } else {
             console.error("Error Message:", error.message);
        }
         console.error("Error Stack:", error.stack);

        return res.status(500).json({
          error: "Internal Server Error",
          details: error.message || "An unexpected error occurred."
        });
      }
    });
  }
);
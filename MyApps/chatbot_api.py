from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.responses import FileResponse
from langchain_ollama import OllamaLLM
from langchain_core.prompts import ChatPromptTemplate

# Initialize chatbot
model = OllamaLLM(model="llama3.2")
template = """
Answer the question below.

Here is the conversation history: {context}

Question: {question}

Answer:
"""
prompt = ChatPromptTemplate.from_template(template)
chain = prompt | model
context = ""

# Initialize FastAPI
app = FastAPI()

class ChatRequest(BaseModel):
    message: str

@app.post("/chat/")
async def chat_endpoint(request: ChatRequest):
    global context
    user_input = request.message

    # Get response from the chatbot
    result = chain.invoke({"context": context, "question": user_input})
    
    # Update context
    context += f"\nUser: {user_input}\nAI: {result}"

    return {"response": result}

@app.get("/favicon.ico")
async def favicon():
    return FileResponse("favicon.ico")  # Place a `favicon.ico` file in the same folder

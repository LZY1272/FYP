# from fastapi import FastAPI
# from pydantic import BaseModel
# from fastapi.responses import FileResponse
# from langchain_ollama import OllamaLLM
# from langchain_core.prompts import ChatPromptTemplate

# # Initialize chatbot
# model = OllamaLLM(model="llama3.2")
# template = """
# Answer the question below.

# Here is the conversation history: {context}

# Question: {question}

# Answer:
# """
# prompt = ChatPromptTemplate.from_template(template)
# chain = prompt | model
# context = ""

# # Initialize FastAPI
# app = FastAPI()

# class ChatRequest(BaseModel):
#     message: str

# @app.post("/chat/")
# async def chat_endpoint(request: ChatRequest):
#     global context
#     user_input = request.message

#     # Get response from the chatbot
#     result = chain.invoke({"context": context, "question": user_input})
    
#     # Update context
#     context += f"\nUser: {user_input}\nAI: {result}"

#     return {"response": result}

# @app.get("/favicon.ico")
# async def favicon():
#     return FileResponse("favicon.ico")  # Place a `favicon.ico` file in the same folder



from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.responses import FileResponse
from langchain_ollama import OllamaLLM, OllamaEmbeddings
from langchain_core.prompts import ChatPromptTemplate
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import (
    TextLoader, 
    DirectoryLoader,
    PyPDFLoader
)
from langchain_community.vectorstores import Chroma
import os
import glob
from langchain_chroma import Chroma

# Initialize FastAPI
app = FastAPI()

# Create directories for storage
os.makedirs("travel_docs", exist_ok=True)
os.makedirs("db", exist_ok=True)

# Initialize embeddings and language model
embeddings = OllamaEmbeddings(model="llama3.2")
model = OllamaLLM(model="llama3.2")

# Initialize chat history
context = ""

# Function to load and process travel documents
def load_travel_knowledge():
    # Check if vector store already exists
    if os.path.exists("db") and len(os.listdir("db")) > 0:
        print("Loading existing vector database...")
        return Chroma(persist_directory="db", embedding_function=embeddings)
    
    print("Creating new vector database from travel documents...")
    
    # Load travel documents
    documents = []
    
    # Load text files
    if glob.glob("travel_docs/*.txt"):
        text_loader = DirectoryLoader(
            "travel_docs", 
            glob="*.txt", 
            loader_cls=TextLoader,
            loader_kwargs={"encoding": "utf-8"}  # Try this encoding first
        )
        try:
            documents.extend(text_loader.load())
        except Exception as e:
            print(f"Error with UTF-8 encoding, trying with 'latin-1': {str(e)}")
            # If UTF-8 fails, try with latin-1 which is more forgiving
            text_loader = DirectoryLoader(
                "travel_docs", 
                glob="*.txt", 
                loader_cls=TextLoader,
                loader_kwargs={"encoding": "latin-1"}
            )
            documents.extend(text_loader.load())
    
    # Load PDF files
    for pdf_file in glob.glob("travel_docs/*.pdf"):
        pdf_loader = PyPDFLoader(pdf_file)
        documents.extend(pdf_loader.load())
    
    # Add metadata to documents
    for doc in documents:
        doc.metadata["source"] = os.path.basename(doc.metadata.get("source", "unknown"))
    
    if not documents:
        print("No documents found in travel_docs directory!")
        return None
    
    # Split documents into chunks
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=1000,
        chunk_overlap=200
    )
    splits = text_splitter.split_documents(documents)
    
    # Create vector store
    vector_db = Chroma.from_documents(
        documents=splits,
        embedding=embeddings,
        persist_directory="db"
    )
    
    print(f"Vector database created with {len(splits)} chunks from {len(documents)} documents")
    return vector_db

# Load travel knowledge base
vector_db = load_travel_knowledge()

# RAG prompt template
rag_template = """
You are TravelMind, an AI assistant specialized in travel planning and recommendations.
Use the following retrieved information to answer the traveler's question.
If you don't know the answer based on the retrieved information, just say that you don't have enough information about this specific query, but try to provide general travel advice that might be helpful.

Retrieved information:
{context}

Chat history:
{chat_history}

Traveler's question: {question}

Your response (be helpful, conversational, and specific when possible):
"""

rag_prompt = ChatPromptTemplate.from_template(rag_template)

# Initialize simple template for when no documents are available
simple_template = """
You are TravelMind, an AI assistant specialized in travel planning and recommendations.
Answer the question below based on your general knowledge about travel.

Chat history: {context}

Traveler's question: {question}

Your response (be helpful, conversational, and specific when possible):
"""
simple_prompt = ChatPromptTemplate.from_template(simple_template)

# Request model
class ChatRequest(BaseModel):
    message: str

@app.post("/chat/")
async def chat_endpoint(request: ChatRequest):
    global context
    user_input = request.message

    if vector_db is None:
        # If no documents are loaded, use the regular chain
        chain = simple_prompt | model
        result = chain.invoke({"context": context, "question": user_input})
    else:
        # Use RAG chain when documents are available
        retriever = vector_db.as_retriever(search_kwargs={"k": 3})
        rag_chain = (
            {"context": retriever, "chat_history": lambda x: context, "question": lambda x: x}
            | rag_prompt
            | model
        )
        result = rag_chain.invoke(user_input)
    
    # Update context (keep limited history to avoid token issues)
    context_parts = context.split("\n")
    if len(context_parts) > 20:  # Keep last 10 exchanges (20 lines)
        context = "\n".join(context_parts[-20:])
    
    context += f"\nUser: {user_input}\nAI: {result}"

    return {"response": result}

@app.get("/favicon.ico")
async def favicon():
    return FileResponse("favicon.ico")
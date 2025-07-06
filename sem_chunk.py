import json
from typing import List, Dict
from langchain.text_splitter import RecursiveCharacterTextSplitter

def load_json_data(file_path: str) -> List[Dict]:
    """Load JSON data from file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            data = json.load(file)
        return data
    except FileNotFoundError:
        raise FileNotFoundError(f"File not found: {file_path}")
    except json.JSONDecodeError:
        raise ValueError(f"Invalid JSON format in file: {file_path}")

def create_semantic_chunks(text: str, chunk_size: int = 4000, chunk_overlap: int = 400) -> List[str]:
    """Create semantic chunks using RecursiveCharacterTextSplitter."""
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size,
        chunk_overlap=chunk_overlap,
        length_function=len,
        separators=["\n\n", "\n", ".", "!", "?", ",", " ", ""]
    )

    if text.strip():
        return text_splitter.split_text(text)
    return []

def process_documents(input_file: str, output_file: str):
    """Process documents and create chunks."""
    try:
        print("Loading JSON data...")
        documents = load_json_data(input_file)
        
        processed_documents = []
        print(f"Processing {len(documents)} documents...")
        
        for doc in documents:
            # Get the content and remove it from the document
            content = doc.pop('content', '')
            
            # Create chunks from the content
            chunks = create_semantic_chunks(content)
            
            # Create new documents with chunks
            for chunk in chunks:
                new_doc = doc.copy()  # Copy all other fields
                new_doc['chunk'] = chunk  # Add the chunk
                processed_documents.append(new_doc)
        
        # Save to new JSON file
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(processed_documents, f, ensure_ascii=False, indent=2)
            
        print(f"Successfully processed {len(documents)} documents into {len(processed_documents)} chunks")
        print(f"Output saved to {output_file}")
        
    except Exception as e:
        print(f"An error occurred: {str(e)}")

def main():
    input_file = "final-output.json"
    output_file = "final-chunks.json"
    process_documents(input_file, output_file)

if __name__ == "__main__":
    main()
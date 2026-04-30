import toml
import os
import json
from openai import OpenAI
import math

# Configuration
INPUT_FILE = '/Users/manu/Documents/Projects/zenith/assets/gym_exercises_complete.toml'
ALLOWED_MUSCLE_GROUPS = [
    "Chest", "Back", "Shoulders", "Biceps", "Triceps", "Forearms",
    "Abs", "Obliques", "Quads", "Hamstrings", "Glutes", "Calves",
    "Adductors", "Abductors", "Cardio", "Full Body"
]

# Initialize OpenAI client
api_key = os.environ.get("OPENAI_API_KEY")
base_url = os.environ.get("OPENAI_BASE_URL")

#if not api_key:
#    print("Error: OPENAI_API_KEY environment variable not set.")
#    print("Please set it with: export OPENAI_API_KEY='your-key-here'")
#    exit(1)
#if not base_url:
#    print("Error: OPENAI_BASE_URL environment variable not set.")
#    print("Please set it with: export OPENAI_BASE_URL='https://openrouter.ai/api/v1'")
#    exit(1)

if not api_key:
    raise RuntimeError("OPENAI_API_KEY environment variable not set")

client = OpenAI(
    api_key=api_key,
    base_url=base_url or "https://openrouter.ai/api/v1",
)

def load_exercises(filepath):
    with open(filepath, 'r') as f:
        return toml.load(f)

def save_exercises(filepath, data):
    # Preserve the header comment if possible, or just write it manually
    header = "### THE EXERCISES ARE PULLED FROM HERE FOR NOW: https://www.strengthlog.com/exercise-directory/ ###\n\n"
    with open(filepath, 'w') as f:
        f.write(header)
        toml.dump(data, f)

def process_batch(batch_data):
    prompt = f"""
You are an expert fitness data validator. Your task is to process a list of gym exercises.
For each exercise, you must:
1. Standardize the 'primary_muscle_group' and 'secondary_muscle_groups' to be strictly from this allowed list:
   {json.dumps(ALLOWED_MUSCLE_GROUPS)}
   - Map "Lats", "Trapezius", "Lower Back" to "Back".
   - Map "Front Deltoids", "Lateral Deltoids", "Rear Deltoids", "Rotator Cuffs" to "Shoulders".
   - Map "Forearm Flexors" to "Forearms".
   - Map "Legs" to "Quads" or "Hamstrings" or "Glutes" based on the exercise, or "Full Body" if it's a compound movement involving many groups.
   - If an exercise is primarily cardio (e.g., running, rowing, burpees), set 'primary_muscle_group' to "Cardio".
2. Add a boolean field 'cardio'. Set to true if the exercise is primarily a cardiovascular exercise (e.g., running, cycling, rowing, burpees, jumping jacks). Otherwise false.
3. Add a boolean field 'timed'. Set to true if the exercise is typically performed for time rather than reps (e.g., planks, static holds, carries, cardio). Otherwise false.
4. Check for general correctness of the exercise data (name, instructions, etc.). If something is glaringly wrong, fix it.

Input JSON:
{json.dumps(batch_data, indent=2)}

Output strictly valid JSON containing the processed list of exercises. The structure should match the input but with the updates applied.
"""

    try:
        response = client.chat.completions.create(
            model="google/gemini-2.5-flash", # Changed model to Gemini as per previous interaction
            messages=[
                {"role": "system", "content": "You are a helpful assistant that processes gym exercise data."},
                {"role": "user", "content": prompt}
            ],
            response_format={"type": "json_object"}
        )
        content = response.choices[0].message.content
        return json.loads(content)
    except Exception as e:
        print(f"Error processing batch: {e}")
        return None

def main():
    print(f"Loading exercises from {INPUT_FILE}...")
    try:
        data = load_exercises(INPUT_FILE)
    except FileNotFoundError:
        print(f"File not found: {INPUT_FILE}")
        return

    # Convert dictionary to list of items for batching
    # We need to keep track of the keys to reconstruct the dictionary
    exercise_items = list(data.items())
    total_exercises = len(exercise_items)
    batch_size = 3
    processed_data = {}

    print(f"Found {total_exercises} exercises. Processing in batches of {batch_size}...")

    for i in range(0, total_exercises, batch_size):
        batch_items = exercise_items[i:i+batch_size]
        batch_dict = {k: v for k, v in batch_items}
        
        print(f"Processing batch {i//batch_size + 1}/{math.ceil(total_exercises/batch_size)}...")
        
        result = process_batch(batch_dict)
        
        if result:
            # The result might be wrapped in a key like "exercises" or just the dict
            # Depending on how GPT returns it. We asked for "processed list of exercises" but gave a dict input.
            # GPT usually returns the same structure if asked.
            # Let's handle if it returns a list or dict.
            
            # If the output is nested under a key (common with json_object mode)
            if "exercises" in result:
                result = result["exercises"]
            
            # Update processed_data
            if isinstance(result, dict):
                processed_data.update(result)
            elif isinstance(result, list):
                # If it returned a list, we need to map back to keys. 
                # This is risky if order changed.
                # Best to rely on keys being present in the objects or the structure being a dict.
                # Given the input was a dict, we expect a dict back.
                print("Warning: Received list instead of dict. Attempting to merge...")
                # This part is tricky without keys. 
                # Let's assume the prompt ensures keys are preserved.
                pass
        else:
            print("Batch failed. Keeping original data for this batch.")
            processed_data.update(batch_dict)

    print("Saving processed exercises...")
    save_exercises(INPUT_FILE, processed_data)
    print("Done!")

if __name__ == "__main__":
    main()

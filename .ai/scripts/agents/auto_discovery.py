"""
AgentBrain Skill Auto-Discovery.
Analyzes completed tasks/worktrees, extracts reusable skills,
and registers them into the AgentBrain knowledge base.
"""

import os
import sys
import re

# Ensure workspace root is in path
_WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
if _WORKSPACE_ROOT not in sys.path:
    sys.path.append(_WORKSPACE_ROOT)

def extract_skills_from_worktree(worktree_path: str):
    """
    Read task walkthrough or git changes in the completed worktree
    and extract reusable coding skills using Gemini API.
    """
    print(f"[Brain] Scanning {worktree_path} for new skills...")
    walkthrough_paths = [
        os.path.join(worktree_path, "walkthrough.md"),
        os.path.join(worktree_path, "README.md"),
        os.path.join(worktree_path, "STATE.md")
    ]
    
    source_content = ""
    for path in walkthrough_paths:
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f:
                source_content += f"\n--- Source: {os.path.basename(path)} ---\n"
                source_content += f.read()

    # If no files found, try to scan Python files
    if not source_content.strip():
        print("[Brain] No walkthrough or project state docs found. Scanning src/ directory...")
        src_dir = os.path.join(worktree_path, "src")
        if os.path.exists(src_dir):
            for root, _, files in os.walk(src_dir):
                for file in files:
                    if file.endswith((".py", ".js", ".ts", ".ps1", ".sh")):
                        with open(os.path.join(root, file), "r", encoding="utf-8", errors="ignore") as f:
                            source_content += f"\n--- Source: {file} ---\n"
                            source_content += f.read()[:1000] # Grab first 1000 chars

    if not source_content.strip():
        print("[Brain] No content found to analyze for skills.")
        return

    # Call Google Gemini API
    try:
        import google.generativeai as genai
        api_key = os.environ.get("GOOGLE_API_KEY")
        if not api_key:
            print("[Brain] GOOGLE_API_KEY environment variable not set. Skipping LLM skill discovery.")
            return

        genai.configure(api_key=api_key)
        model = genai.GenerativeModel("gemini-1.5-flash")
        
        prompt = f"""
You are the AgentRealm Brain Orchestrator. 
Analyze the following implementation source content from a completed worktree:

{source_content}

Your goal is to extract EXACTLY ONE highly reusable, structured "Skill" (learned pattern, system setup, or coding guideline) that other agents should follow.
Format the output as a standard AgentBrain Skill document in Markdown:
1. Title: A clean, descriptive title prefixing "# Skill: "
2. Description: What this skill does, when to use it, and why it is important.
3. Code Example / Implementation Details: Concrete code patterns or configs.
4. Lessons Learned / Gotchas: Key pitfalls to avoid.

Do not include any intro/outro text, just output the raw Markdown content.
"""
        print("[Brain] Querying Gemini for skill extraction...")
        response = model.generate_content(prompt)
        skill_markdown = response.text.strip()
        
        # Save the skill
        # Extract title to name the file
        title_match = re.search(r"^# Skill:\s*(.*)", skill_markdown, re.MULTILINE)
        if title_match:
            skill_title = title_match.group(1).strip()
        else:
            skill_title = "Discovered Skill"
            
        safe_name = re.sub(r"\W+", "_", skill_title.lower()).strip("_")
        
        # Determine brain path
        from ai.rag_core.embeddings import _read_rag_mode
        # Read env for brain path
        brain_path = os.environ.get("GLOBAL_BRAIN_PATH")
        if not brain_path:
            # Fallback to local brain
            brain_path = os.path.join(_WORKSPACE_ROOT, ".ai", "brain")
            
        skills_dir = os.path.join(brain_path, "skills")
        os.makedirs(skills_dir, exist_ok=True)
        
        skill_file = os.path.join(skills_dir, f"{safe_name}.md")
        with open(skill_file, "w", encoding="utf-8") as f:
            f.write(skill_markdown)
            
        print(f"🧠 Discovered & registered skill successfully: {skill_file}")
        
    except Exception as e:
        print(f"[Brain] Error during skill discovery: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python auto_discovery.py <path_to_completed_worktree>")
        sys.exit(1)
    extract_skills_from_worktree(sys.argv[1])

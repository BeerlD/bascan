import re
import sys
import argparse
import google.generativeai as genai

class ArgParseExtended(argparse.ArgumentParser):
    def error(self, message):
        missing_args = re.findall(r'the following arguments are required: (.+)', message)
        
        if missing_args:
            missing_args = missing_args[0].split(', ')

            for arg in missing_args:
                argName = arg.lstrip('-')
                print(f"\033[31mERROR\033[0m: Configure the {arg} with \033[47m\033[30moption set {arg} <value>\033[0m.", file=sys.stderr)
            
        elif message == "argument --message: expected one argument":
            print(f"\033[31mERROR\033[0m: Do at least one scan.", file=sys.stderr)
        else:
            print(message, file=sys.stderr)
        
        sys.exit(2)

parser = ArgParseExtended(description="Gemini Pro IA Chat")
parser.add_argument("--message", required=True, help="Message will be send.")
parser.add_argument("--geminiToken", required=True, help="IA access token.")
args = parser.parse_args()

API_KEY = args.geminiToken
genai.configure(api_key=API_KEY)
model = genai.GenerativeModel("gemini-2.0-flash")
response = model.generate_content(args.message)
print(response.text)

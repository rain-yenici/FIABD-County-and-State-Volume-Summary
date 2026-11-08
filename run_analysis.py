from pathlib import Path
import subprocess

project_dir = Path(__file__).resolve().parent
r_script_path = project_dir / "FIA Analysis.R"

rscript = r"C:\PROGRA~1\R\R-44~1.1\bin\x64\Rscript.exe"


states = {
    "alabama": "AL",
    "alaska": "AK",
    "arizona": "AZ",
    "arkansas": "AR",
    "california": "CA",
    "colorado": "CO",
    "connecticut": "CT",
    "delaware": "DE",
    "florida": "FL",
    "georgia": "GA",
    "hawaii": "HI",
    "idaho": "ID",
    "illinois": "IL",
    "indiana": "IN",
    "iowa": "IA",
    "kansas": "KS",
    "kentucky": "KY",
    "louisiana": "LA",
    "maine": "ME",
    "maryland": "MD",
    "massachusetts": "MA",
    "michigan": "MI",
    "minnesota": "MN",
    "mississippi": "MS",
    "missouri": "MO",
    "montana": "MT",
    "nebraska": "NE",
    "nevada": "NV",
    "new hampshire": "NH",
    "new jersey": "NJ",
    "new mexico": "NM",
    "new york": "NY",
    "north carolina": "NC",
    "north dakota": "ND",
    "ohio": "OH",
    "oklahoma": "OK",
    "oregon": "OR",
    "pennsylvania": "PA",
    "rhode island": "RI",
    "south carolina": "SC",
    "south dakota": "SD",
    "tennessee": "TN",
    "texas": "TX",
    "utah": "UT",
    "vermont": "VT",
    "virginia": "VA",
    "washington": "WA",
    "west virginia": "WV",
    "wisconsin": "WI",
    "wyoming": "WY"
}

print("====================================")
print("     FIA COUNTY VOLUME EXTRACTOR")
print("====================================")


while True:
    user_input = input("\nEnter state name for analysis: ").strip().lower()

    if user_input in states:
        state_name = user_input.title()
        state_abbr = states[user_input]
        break

    else:
        print("Invalid state. Please enter a valid US state.")

print(f"\nSelected state: {state_name}")
print(f"FIA abbreviation: {state_abbr}")

print("\nStarting FIA extraction...\n")

try: 
    subprocess.run(
        [
            rscript,
            str(r_script_path),
            state_name,
            state_abbr
        ],
        cwd=project_dir,
        check=True
    )

    print("\nExtraction completed successfully!")

except subprocess.CalledProcessError:
    print("\nError: R extraction failed.")

except FileNotFoundError:
    print("\nError: Rscript was not found.")
from csv import DictReader
from sys import exit

labeled_variables = set()

with open("./metadata/variable_categories.csv", "r", encoding="utf-8") as file:
    reader = DictReader(file)
    for line in reader:
        labeled_variables.add(
            (line["dataset"], line["version"], line.get("variable", line.get("name")))
        )

datasets = set()

with open("./metadata/datasets.csv", "r", encoding="utf-8") as file:
    reader = DictReader(file)
    for line in reader:
        datasets.add(line.get("name", line.get("dataset")))


missing_variables = set()
missing_datasets = set()

with open("./metadata/variables.csv", "r", encoding="utf-8") as file:
    reader = DictReader(file)
    for line in reader:
        if line["dataset"] not in datasets:
            missing_datasets.add(line["dataset"])
        if line["type"] in ["categorical", "group"]:
            _id = (
                line["dataset"],
                line["version"],
                line.get("variable", line.get("name")),
            )
            if _id not in labeled_variables:
                missing_variables.add(_id)

error = False

if missing_datasets:
    missing_datasets_str = ", ".join(missing_datasets)
    print("\ndatasets.csv incomplete.")
    print(f"Missing datasets: {missing_datasets_str}")
    error = True

if missing_variables:
    print("\nVariables missing in variable_categories.csv")
    print("Missing Variables:\n")
    for variable in missing_variables:
        print(f"Dataset: {variable[0]}")
        print(f"Version: {variable[1]}")
        print(f"Variable: {variable[2]}\n")


if error:
    exit(1)

exit(0)

from csv import DictReader
from sys import exit
from urllib import request


def load_variable_variable_categories():
    labeled_variables = set()

    with open("./metadata/variable_categories.csv", "r", encoding="utf-8") as file:
        reader = DictReader(file)
        for line in reader:
            labeled_variables.add(
                (line["dataset"], line["version"], line.get("variable", line.get("name")))
            )
    return labeled_variables


def load_datasets():
    datasets = set()

    with open("./metadata/datasets.csv", "r", encoding="utf-8") as file:
        reader = DictReader(file)
        for line in reader:
            datasets.add(line.get("name", line.get("dataset")))
    return datasets


def load_topics_and_concepts():
    topics = set()
    concepts = {}
    with request.urlopen(
        "https://raw.githubusercontent.com/paneldata/soep-core/master/metadata/topics.csv"
    ) as response:
        reader = DictReader(response.read().decode("utf-8").splitlines())
        for line in reader:
            topics.add(line["name"])

    try:
        with open("./metadata/concepts.csv", "r", encoding="utf-8") as file:
            reader = DictReader(file)
            for line in reader:
                concepts[line["name"]] = line["topic"]
    except FileNotFoundError:
        pass

    with request.urlopen(
        "https://raw.githubusercontent.com/paneldata/soep-core/master/metadata/concepts.csv"
    ) as response:
        reader = DictReader(response.read().decode("utf-8").splitlines())
        for line in reader:
            concepts[line["name"]] = line["topic"]

    return topics, concepts


def find_missing_entities(labeled_variables, datasets, topics, concepts):
    missing_variables = set()
    missing_datasets = set()
    faulty_variable_concepts = {}

    with open("./metadata/variables.csv", "r", encoding="utf-8") as file:
        reader = DictReader(file)
        for line in reader:
            _id = "name"
            if "name" not in line:
                _id = "variable"
            if line["concept"] in concepts:
                if concepts[line["concept"]] not in topics:
                    faulty_variable_concepts[_id] = {
                        "concept": line["concept"],
                        "topic": concepts[line["concept"]],
                    }
            if line["dataset"] not in datasets:
                missing_datasets.add(line["dataset"])
            if line["type"] in ["categorical", "group"]:
                missing_id = (
                    line["dataset"],
                    line["version"],
                    line.get("variable", line.get("name")),
                )
                if missing_id not in labeled_variables:
                    missing_variables.add(missing_id)
    return missing_variables, missing_datasets, faulty_variable_concepts


def handle_errors(missing_variables, missing_datasets, faulty_variable_concepts):
    error = False

    if missing_datasets:
        error = True
        missing_datasets_str = ", ".join(missing_datasets)
        print("datasets.csv incomplete.")
        print(f"Missing datasets: {missing_datasets_str}")
        print("=" * 20)
        print("-" * 20)
        print("=" * 20)

    if missing_variables:
        error = True
        print("Variables missing in variable_categories.csv")
        print("Missing Variables:")
        for variable in missing_variables:
            print(f"Dataset: {variable[0]}")
            print(f"Version: {variable[1]}")
            print(f"Variable: {variable[2]}")
            print("=" * 20)
            print("-" * 20)
            print("=" * 20)

    if faulty_variable_concepts:
        print("Faulty link in variable->concept->topic relation")
        print("Missing Links:")
        for variable, link in faulty_variable_concepts.items():
            print(f"Variable: {variable}")
            print(f"Concept: {link['concept']}")
            print(f"Topic: {link['topic']}")
            print("=" * 20)
            print("-" * 20)
            print("=" * 20)

    if error:
        exit(1)

    exit(0)


def main():
    labeled_variables = load_variable_variable_categories()
    datasets = load_datasets()
    topics, concepts = load_topics_and_concepts()
    missing_variables, missing_datasets, faulty_variable_concepts = find_missing_entities(
        labeled_variables, datasets, topics, concepts
    )
    handle_errors(missing_variables, missing_datasets, faulty_variable_concepts)


if __name__ == "__main__":
    main()

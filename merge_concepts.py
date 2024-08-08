# %%
from pathlib import Path

import pandas

statistics_path = Path("./").absolute()
core_path = Path("../").absolute()
if statistics_path.name != "statistics":
    statistics_path = statistics_path.joinpath("statistics")
    core_path = Path("./").absolute()

statistics_concepts = pandas.read_csv(statistics_path.joinpath("metadata/concepts.csv"))
statistics_datasets: set[str] = set(statistics_concepts["dataset"].unique())

# %%
core_path = core_path.joinpath("metadata")
core_concepts = pandas.read_csv(core_path.joinpath("concepts.csv"))
core_columns = list(core_concepts.columns)

core_concept_names = set(core_concepts["name"] + core_concepts["topic"])
statistics_concepts["filter"] = statistics_concepts["name"] + statistics_concepts["topic"]
filtered_concepts = statistics_concepts.loc[
    statistics_concepts["filter"].isin(core_concept_names)
].drop("filter", axis=1)

core_concepts_complete = pandas.concat(
    [core_concepts, filtered_concepts], axis=0, ignore_index=True
)[core_columns]

core_concepts_complete.to_csv(
    core_path.joinpath("concepts.csv"), index=False, index_label=False
)

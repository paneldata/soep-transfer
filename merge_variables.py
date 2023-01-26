#%%
from pathlib import Path

import pandas

statistics_path = Path("./").absolute()
core_path = Path("../").absolute()
if statistics_path.name != "statistics":
    statistics_path = statistics_path.joinpath("statistics")
    core_path = Path("./").absolute()

statistics_variables = pandas.read_csv(statistics_path.joinpath("metadata/variables.csv"))
statistics_datasets: set[str] = set(statistics_variables["dataset"].unique())


def statistics_type(row: pandas.Series) -> str:
    if row["meantable"] == "yes" and row["probtable"] == "yes":
        return "ordinal"
    if row["meantable"] == "yes":
        return "numerical"
    if row["probtable"] == "yes":
        return "categorical"
    return ""


statistics_variables["study"] = "soep-core"
statistics_variables["name"] = statistics_variables["variable"]
statistics_variables["type"] = statistics_variables.apply(statistics_type, axis=1)
statistics_variables["statistics"] = statistics_variables["type"] != ""


# %%
core_path = core_path.joinpath("metadata")
core_datasets = pandas.read_csv(core_path.joinpath("datasets.csv"))
core_variables = pandas.read_csv(core_path.joinpath("variables.csv"))
core_variables["statistics"] = False
core_columns = list(core_variables.columns)


core_datasets = core_datasets.loc[~core_datasets["name"].isin(statistics_datasets)]

for dataset in statistics_datasets:
    row = {"study": "soep-core"}
    if dataset.startswith("p"):
        row["analysis_unit"] = "p"
    if dataset.startswith("h"):
        row["analysis_unit"] = "h"
    row["name"] = dataset
    core_datasets = pandas.concat(
        [core_datasets, pandas.DataFrame([row])], ignore_index=True
    )


core_variables = core_variables.loc[~core_variables["dataset"].isin(statistics_datasets)]

core_variables_complete = pandas.concat(
    [core_variables, statistics_variables], axis=0, ignore_index=True
)[core_columns]

core_variables_complete.to_csv(
    core_path.joinpath("variables.csv"), index=False, index_label=False
)
core_datasets.to_csv(core_path.joinpath("datasets.csv"), index=False, index_label=False)

#%%
from pathlib import Path

import pandas

transfer_path = Path("./").absolute()
core_path = Path("../").absolute()
if transfer_path.name != "transfer":
    transfer_path = transfer_path.joinpath("transfer")
    core_path = Path("./").absolute()

statistics_variables = pandas.read_csv(transfer_path.joinpath("metadata/variables.csv"))


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
core_path = core_path.joinpath("metadata/variables.csv")
core_variables = pandas.read_csv(core_path)
core_variables["statistics"] = False
core_columns = list(core_variables.columns)

core_complete = pandas.concat(
    [core_variables, statistics_variables], axis=0, ignore_index=True
)[core_columns]

core_complete.to_csv(core_path, index=False, index_label=False)

# %%

# Aim: This script documents the steps to set up this repo for reproducibility
# and sharing of knowledge/know-how

# The repo was created on github with the following command in the system CLI
# (requires the github cli tool)
# cd papers
# gh repo create odjitter

# Open RStudio and create a project as follows
rstudioapi::openProject("~/papers/odjitter")

# Set-up with usethis
usethis::use_readme_rmd()
unlink(".git/hooks/pre-commit")
# Edit the paper/readme
file.edit("README.Rmd")

usethis::use_github_action("render-rmarkdown")
file.edit(".github/workflows/render-rmarkdown.yaml")

# Get OD data for Edinburgh



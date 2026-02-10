# p-THYROSIM Web Application

Web app for **patient-specific thyroid hormone simulation**: height, weight, sex, and two time modes (hours up to 100 days, days up to 1000 days). Built on the [THYROSIM](http://biocyb1.cs.ucla.edu/thyrosim/) web application (UCLA Biocybernetics Laboratory, Han et al. 2016).

---

## What this repo is

- **Base:** The original THYROSIM internet app (Java ODE solver + Perl CGI + JavaScript), with contents at repo root.
- **Additions:** Updated patient-specific kernel (see `java/`), reference notebook in `refs/`, and task/credits docs.
- **Goal:** Deliver a p-THYROSIM internet app with anthropometric inputs and dual time-scale support (course project).

---

## Repo layout

| Path | Purpose |
|------|--------|
| `java/` | ODE solver (original `Thyrosim.java` + updated kernel when integrated) |
| `cgi-bin/` | CGI entry points |
| `pm/` | Perl backend (THYROSIM.pm, THYROWEB.pm) |
| `js/`, `css/`, `config/` | Frontend and config |
| `refs/` | Reference materials (e.g. p-THYROSIM Jupyter notebook) |
| `docs/` | Documentation (including original THYROSIM README) |

---

## Credits and license

- **THYROSIM (web app and model):** Original code and design from the UCLA Biocybernetics Laboratory (Han et al., 2016). The THYROSIM-derived code in this repository is used under the terms of the original THYROSIM license. See **[License.docx](License.docx)** and **[docs/THYROSIM_ORIGINAL_README.md](docs/THYROSIM_ORIGINAL_README.md)**.
- **p-THYROSIM (model and notebook):** The patient-specific model and Jupyter notebook are from the p-THYROSIM research project (2026 paper). The notebook in `refs/` is for reference and attribution; implementation in this repo is in Java/Perl/JS. Link to the official p-THYROSIM repo/paper when available.

---

## Disclaimer

This tool is for education and research only. It is not a substitute for medical advice; consult a physician for any medical questions or conditions.

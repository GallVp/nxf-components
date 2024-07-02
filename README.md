# NXF-COMPONENTS

A repository of developmental NextFlow DSL2 components meant to be used with [nf-core/tools](https://github.com/nf-core/tools). As soon as a component meets all the nf-core guidelines, it should be submitted to [nf-core/modules](https://github.com/nf-core/modules).

## Setup

## Setup

Use the dev version of the [nf-core/tools](https://github.com/nf-core/tools/tree/dev)

```bash
pip install --upgrade --force-reinstall git+https://github.com/nf-core/tools.git@dev
```

## Steps for Adding a New Component

- `Search`: Search on [nf-core/modules](https://nf-co.re/modules), [GitHub issues](https://github.com/nf-core/modules/issues) and [GitHub PRs](https://github.com/nf-core/modules/pulls)
- `Issue`: Create a new issue on [GitHub issues](https://github.com/nf-core/modules/issues) for module or sub-workflow
- `Create`: Create `nf-core -v modules create tool/subtool` on a tool specific branch
- `Lint`: Lint `nf-core -v modules lint tool/subtool`
- `Test`: Test `nf-core -v modules -g git@github.com:GallVp/nxf-components.git test tool/subtool`
- `Commit`: Commit to this repo
- `Install`: Install `nf-core -v modules -g https://github.com/PlantandFoodResearch/nxf-components.git install tool/subtool`
- `PR`: Create a PR on [nf-core/modules](https://github.com/nf-core/modules/pulls) from a personal fork of [nf-core/modules](https://github.com/nf-core/modules)
- `Status`: Update submission status [below](#submitted-to-nf-coremodules)
- `Remove`: Once the PR is accepted at [nf-core/modules](https://github.com/nf-core/modules/pulls), remove the module from this repo and update submission status [below](#submitted-to-nf-coremodules)

## Submitted to nf-core/modules

Following modules have been submitted and added (✅︎) to nf-core/modules and may be removed (⛔) from this repository without notice.

| Module | Pull request |
| ------ | ------------ |

And [more...](./SUBMITTED.md)

## Hybrid Testing and Hybrid Sub-workflows

Hybrid sub-workflows are not supported by nf-core/tools. See: https://github.com/nf-core/tools/issues/1927

The workaround is to install nf-core modules in the nf-core-modules which is setup as a dummy pipeline. The nf-core modules needed for testing are then symlinked to `modules/nf-core` and the nf-core modules needed for sub-workflows are symlinked to `modules/gallvp`. See: [nf-core-hybridisation.sh](./nf-core-hybridisation.sh)

## References

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).

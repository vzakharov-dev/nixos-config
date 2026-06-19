{ pkgs, ... }:

let
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    pip
    virtualenv
    psycopg2
    sqlalchemy
    pydantic
    polars
    pandas
    numpy
    httpx
    pytest
  ]);
in
{
  home.packages = with pkgs; [
    # Python
    pythonEnv
    uv

    # Databases
    duckdb
    postgresql_18  # только клиент, сервер — в configuration.nix

    # Containers
    podman
    docker-compose

    # DE Tools
    metabase
    zellij

    # Documentation
    glow
    typst
    tinymist
    mermaid-cli
    zathura

    # AI coding
    aider-chat
  ];

  # Переменные окружения для DE
  home.sessionVariables = {
    PYTHONPATH = "$HOME/projects";
    DBT_PROFILES_DIR = "$HOME/.dbt";
    DAGSTER_HOME = "$HOME/.dagster";
  };
}

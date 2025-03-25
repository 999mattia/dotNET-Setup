#!/bin/bash

# Define colors for prettier output
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

# Function to print a step message
print_step() {
  echo -e "\n${CYAN}==> $1${RESET}\n"
}

# Function to print a success message
print_success() {
  echo -e "${GREEN}✔ $1${RESET}\n"
}

# Function to print a warning message
print_warning() {
  echo -e "${YELLOW}! $1${RESET}\n"
}

# Function to print an error message
print_error() {
  echo -e "${RED}✖ $1${RESET}\n"
}

# Prompt the user for the project name
read -p "Enter the project name: " PROJECT_NAME

# Create a new directory for the solution
print_step "Creating directory for the solution..."
mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME" || { print_error "Failed to create or navigate to the directory."; exit 1; }
print_success "Directory '$PROJECT_NAME' created."

# Create the solution
print_step "Creating the solution..."
dotnet new sln -n "$PROJECT_NAME"
print_success "Solution '$PROJECT_NAME.sln' created."

# Define project names and types
declare -A PROJECTS
PROJECTS=(
  ["$PROJECT_NAME.Core"]="classlib"
  ["$PROJECT_NAME.Infrastructure"]="classlib"
  ["$PROJECT_NAME.Infrastructure.Contracts"]="classlib"
  ["$PROJECT_NAME.Business"]="classlib"
  ["$PROJECT_NAME.Business.Contracts"]="classlib"
  ["$PROJECT_NAME.Presentation"]="webapi"
)

# Create projects and add them to the solution
print_step "Creating projects and adding them to the solution..."
for PROJECT in "${!PROJECTS[@]}"; do
  print_step "Creating project '$PROJECT' (${PROJECTS[$PROJECT]})..."
  dotnet new "${PROJECTS[$PROJECT]}" -n "$PROJECT" -o "$PROJECT"
  dotnet sln add "$PROJECT/$PROJECT.csproj"
  print_success "Project '$PROJECT' created and added to the solution."
done

# Add project references
print_step "Adding project references..."
dotnet add "$PROJECT_NAME.Infrastructure.Contracts/$PROJECT_NAME.Infrastructure.Contracts.csproj" reference \
  "$PROJECT_NAME.Core/$PROJECT_NAME.Core.csproj"

dotnet add "$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj" reference \
  "$PROJECT_NAME.Infrastructure.Contracts/$PROJECT_NAME.Infrastructure.Contracts.csproj" \
  "$PROJECT_NAME.Core/$PROJECT_NAME.Core.csproj"

dotnet add "$PROJECT_NAME.Business.Contracts/$PROJECT_NAME.Business.Contracts.csproj" reference \
  "$PROJECT_NAME.Core/$PROJECT_NAME.Core.csproj"

dotnet add "$PROJECT_NAME.Business/$PROJECT_NAME.Business.csproj" reference \
  "$PROJECT_NAME.Core/$PROJECT_NAME.Core.csproj" \
  "$PROJECT_NAME.Business.Contracts/$PROJECT_NAME.Business.Contracts.csproj" \
  "$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj" \
  "$PROJECT_NAME.Infrastructure.Contracts/$PROJECT_NAME.Infrastructure.Contracts.csproj"

dotnet add "$PROJECT_NAME.Presentation/$PROJECT_NAME.Presentation.csproj" reference \
  "$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj" \
  "$PROJECT_NAME.Infrastructure.Contracts/$PROJECT_NAME.Infrastructure.Contracts.csproj" \
  "$PROJECT_NAME.Business/$PROJECT_NAME.Business.csproj" \
  "$PROJECT_NAME.Business.Contracts/$PROJECT_NAME.Business.Contracts.csproj"
print_success "Project references added."

# Install NuGet packages (one at a time)
print_step "Installing NuGet packages..."
dotnet add "$PROJECT_NAME.Infrastructure.Contracts/$PROJECT_NAME.Infrastructure.Contracts.csproj" package Microsoft.EntityFrameworkCore

dotnet add "$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj" package Microsoft.EntityFrameworkCore
dotnet add "$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj" package Microsoft.EntityFrameworkCore.Design
dotnet add "$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj" package Microsoft.Extensions.Configuration.Json
dotnet add "$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj" package Npgsql.EntityFrameworkCore.PostgreSQL

dotnet add "$PROJECT_NAME.Presentation/$PROJECT_NAME.Presentation.csproj" package AutoMapper
dotnet add "$PROJECT_NAME.Presentation/$PROJECT_NAME.Presentation.csproj" package Microsoft.AspNetCore.OpenApi
dotnet add "$PROJECT_NAME.Presentation/$PROJECT_NAME.Presentation.csproj" package Swashbuckle.AspNetCore
dotnet add "$PROJECT_NAME.Presentation/$PROJECT_NAME.Presentation.csproj" package Microsoft.AspNetCore.Authentication.JwtBearer
dotnet add "$PROJECT_NAME.Presentation/$PROJECT_NAME.Presentation.csproj" package System.IdentityModel.Tokens.Jwt
print_success "NuGet packages installed."

# Enable XML documentation generation for all projects
print_step "Enabling XML documentation generation for all projects..."
for PROJECT in "${!PROJECTS[@]}"; do
  CS_PROJ_FILE="$PROJECT/$PROJECT.csproj"
  if [ -f "$CS_PROJ_FILE" ]; then
    # Add <GenerateDocumentationFile>true</GenerateDocumentationFile> to the PropertyGroup
    sed -i '/<PropertyGroup>/a \ \ \ \ <GenerateDocumentationFile>true</GenerateDocumentationFile>' "$CS_PROJ_FILE"
    print_success "Enabled XML documentation for '$PROJECT'."
  else
    print_warning "Could not find '$CS_PROJ_FILE'. Skipping XML documentation generation."
  fi
done

# Output success message
print_success "Solution and projects created successfully!"
echo -e "${CYAN}Navigate to the '$PROJECT_NAME' directory and start coding!${RESET}\n"

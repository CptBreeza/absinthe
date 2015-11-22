defmodule ExGraphQL.Execution do

  alias ExGraphQL.Language
  alias ExGraphQL.Type

  @type t :: %{schema: Type.Schema.t, document: Language.Document.t, context: map, variables: map, validate: boolean, selected_operation: ExGraphQL.Type.ObjectType.t, operation_name: atom, result: map}
  defstruct schema: nil, document: nil, context: %{}, variables: %{}, fragments: %{}, operations: %{}, validate: true, selected_operation: nil, operation_name: nil, result: %{}

  def run(execution, options \\ []) do
    raw = execution |> Map.merge(options |> Enum.into(%{}))
    case prepare(raw) do
      {:ok, prepared} -> execute(prepared)
      other -> other
    end
  end

  def prepare(execution) do
    defined = execution |> categorize_definitions
    case selected_operation(defined) do
      {:ok, operation} ->
        %{defined | selected_operation: operation}
        |> set_variables
        |> validate
      other -> other
    end
  end

  # TODO: We're not actually doing the execution yet
  defp execute(execution) do
    {:ok, execution}
  end

  @doc "Categorize definitions in the execution document as operations or fragments"
  @spec categorize_definitions(t) :: t
  def categorize_definitions(%{document: %Language.Document{definitions: definitions}} = execution) do
    categorize_definitions(%{execution | operations: %{}, fragments: %{}}, definitions)
  end

  defp categorize_definitions(execution, []) do
    execution
  end
  defp categorize_definitions(%{operations: operations} = execution, [%{__struct__: ExGraphQL.Language.OperationDefinition, name: name} = definition | rest]) do
    categorize_definitions(%{execution | operations: operations |> Map.put(name, definition)}, rest)
  end
  defp categorize_definitions(%{fragments: fragments} = execution, [%{__struct__: ExGraphQL.Language.FragmentDefinition, name: name} = definition | rest]) do
    categorize_definitions(%{execution | fragments: fragments |> Map.put(name, definition)}, rest)
  end

  @doc "Validate an execution"
  @spec validate(t) :: {:ok, t} | {:error, binary}
  def validate(%{validate: true}) do
    {:error, "Validation is not currently supported"}
  end
  def validate(execution) do
    {:ok, execution}
  end

  def selected_operation(%{selected_operation: value}) when not is_nil(value) do
    {:ok, value}
  end
  def selected_operation(%{operations: ops, operation_name: nil}) when ops == %{} do
    {:ok, nil}
  end
  def selected_operation(%{operations: ops, operation_name: nil}) when map_size(ops) == 1 do
    op = ops |> Map.values |> List.first
    {:ok, op}
  end
  def selected_operation(%{operations: ops, operation_name: name}) do
    case Map.get(ops, name) do
      nil -> {:error, "No operation with name: #{name}"}
      op -> {:ok, op}
    end
  end
  def selected_operation(%{operations: ops, operation_name: nil}) do
    {:error, "Multiple operations available, but no operation_name provided"}
  end

  def set_variables(%{schema: schema, variables: variables} = execution) do
    execution
  end

end
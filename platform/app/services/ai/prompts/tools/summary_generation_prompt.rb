# frozen_string_literal: true

module Ai
  module Prompts
    module Tools
      class SummaryGenerationPrompt
        def self.content(user_query:, data_results:, additional_context: nil)
          <<~INSTRUCTIONS
            You are a data analysis assistant. Generate a comprehensive Markdown-formatted summary based on the following:

            **User Query**:#{" "}
            #{user_query}

            **Data Results**:
            #{data_results.to_yaml}

            #{additional_context ? "**Additional Context**:\n#{additional_context}" : ""}

            **Requirements**:
            - Structure the summary using Markdown with these sections:
              ## Analysis Overview
              ## Key Insights
              ## Data Quality Notes
            - Use bullet points for lists
            - Highlight important trends/patterns
            - Flag any data inconsistencies or missing values
            - Maintain professional tone for business users
            - Keep insights actionable and data-driven

            {format_instructions}
          INSTRUCTIONS
        end
      end
    end
  end
end

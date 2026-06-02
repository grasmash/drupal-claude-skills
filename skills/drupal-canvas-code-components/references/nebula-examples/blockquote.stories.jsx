import Blockquote from "@/components/blockquote";

export default {
  title: "Components/Blockquote",
  component: Blockquote,
  argTypes: {
    textColor: {
      control: "select",
      options: ["dark", "light"],
    },
  },
};

export const Default = {
  args: {
    text: "Insert a quote...",
    textColor: "dark",
  },
};

export const WithAttribution = {
  args: {
    text: "The best way to predict the future is to create it.",
    textColor: "dark",
    name: "Peter Drucker",
    title: "Management Consultant",
  },
};

export const LongQuote = {
  args: {
    text: "Innovation distinguishes between a leader and a follower. Your time is limited, so don't waste it living someone else's life. Don't be trapped by dogma — which is living with the results of other people's thinking.",
    textColor: "dark",
    name: "Steve Jobs",
    title: "Co-founder, Apple Inc.",
  },
};

export const LightOnDark = {
  args: {
    text: "The only way to do great work is to love what you do.",
    textColor: "light",
    name: "Steve Jobs",
    title: "Co-founder, Apple Inc.",
  },
  decorators: [
    (Story) => (
      <div className="bg-slate-800 p-8">
        <Story />
      </div>
    ),
  ],
};

export const WithoutAttribution = {
  args: {
    text: "Simplicity is the ultimate sophistication.",
    textColor: "dark",
  },
};

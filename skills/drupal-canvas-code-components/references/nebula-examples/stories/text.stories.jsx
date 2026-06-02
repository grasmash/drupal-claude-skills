import Text from "@/components/text";

const exampleArgs = {
  text: "Enter some text...",
  textSize: "normal",
  textColor: "dark",
};

export default {
  title: "Components/Text",
  component: Text,
  argTypes: {
    textSize: {
      control: "select",
      options: ["extra_small", "small", "normal", "large", "extra_large"],
    },
    textColor: {
      control: "select",
      options: ["dark", "light"],
    },
  },
};

export const Default = {
  args: exampleArgs,
};

export const ExtraSmall = {
  args: {
    ...exampleArgs,
    textSize: "extra_small",
  },
};

export const Small = {
  args: {
    ...exampleArgs,
    textSize: "small",
  },
};

export const Normal = {
  args: {
    ...exampleArgs,
    textSize: "normal",
  },
};

export const Large = {
  args: {
    ...exampleArgs,
    textSize: "large",
  },
};

export const ExtraLarge = {
  args: {
    ...exampleArgs,
    textSize: "extra_large",
  },
};

export const LightOnDark = {
  args: {
    ...exampleArgs,
    textColor: "light",
  },
  decorators: [
    (Story) => (
      <div className="bg-slate-800 p-8">
        <Story />
      </div>
    ),
  ],
};

export const WithHTML = {
  args: {
    text: "<p>This is a <strong>bold</strong> and <em>italic</em> text with a <a href='#'>link</a>.</p>",
    textSize: "normal",
    textColor: "dark",
  },
};

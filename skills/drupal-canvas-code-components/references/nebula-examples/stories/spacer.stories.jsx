import Spacer from "@/components/spacer";

export default {
  title: "Components/Spacer",
  component: Spacer,
  argTypes: {
    height: {
      control: "select",
      options: ["small", "medium", "large", "extra_large"],
    },
  },
  decorators: [
    (Story) => (
      <div className="flex flex-col">
        <div className="bg-blue-100 p-4 text-center text-blue-800">Above</div>
        <div className="bg-gray-200">
          <Story />
        </div>
        <div className="bg-blue-100 p-4 text-center text-blue-800">Below</div>
      </div>
    ),
  ],
};

export const Default = {
  args: {
    height: "medium",
  },
};

export const Small = {
  args: {
    height: "small",
  },
};

export const Large = {
  args: {
    height: "large",
  },
};

export const ExtraLarge = {
  args: {
    height: "extra_large",
  },
};

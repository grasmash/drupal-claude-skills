import SearchButton from "@/components/search_button";

export default {
  title: "Components/Search Button",
  component: SearchButton,
  parameters: {
    layout: "fullscreen",
  },
};

export const Default = {};

export const InHeader = {
  args: {
    positionTop: 60,
  },
  decorators: [
    (Story) => (
      <div className="relative">
        <div className="flex h-[60px] items-center justify-end bg-white px-4 shadow">
          <Story />
        </div>
        <div className="h-[200px] bg-gray-50 p-4">
          <p className="text-gray-500">Page content below header</p>
        </div>
      </div>
    ),
  ],
};

import Header from "@/components/header";
import Logo from "@/components/logo";
import MainNavigation from "@/components/main_navigation";

export default {
  title: "Components/Header",
  component: Header,
  parameters: {
    layout: "fullscreen",
  },
  argTypes: {
    displaySearchForm: {
      control: "boolean",
    },
    backgroundColor: {
      control: "color",
    },
  },
};

export const Default = {
  args: {
    displaySearchForm: true,
    backgroundColor: "#ffffff",
    logo: <Logo />,
    menu: <MainNavigation />,
  },
};

export const WithoutSearch = {
  args: {
    displaySearchForm: false,
    backgroundColor: "#ffffff",
    logo: <Logo />,
    menu: <MainNavigation />,
  },
};

export const CustomBackground = {
  args: {
    displaySearchForm: true,
    backgroundColor: "#F8FAFC",
    logo: <Logo />,
    menu: <MainNavigation />,
  },
};

import { useEffect, useRef, useState } from "react";
import SearchButton from "@/components/search_button";
import { cva } from "class-variance-authority";
import { cn } from "drupal-canvas";

const headerVariants = cva(
  cn(
    "relative grid w-full justify-center gap-4 px-8 py-3 leading-[normal]",
    "border-b border-solid border-gray-200",
    "bg-[var(--color-bg)]",
  ),
  {
    variants: {
      displaySearchForm: {
        false: "grid-cols-2",
        true: "grid-cols-2 md:grid-cols-[1fr_auto_1fr]",
      },
    },
  },
);

const Header = ({
  backgroundColor = "#ffffff",
  className,
  logo,
  menu,
  displaySearchForm,
}) => {
  const [height, setHeight] = useState(0);
  const ref = useRef(null);

  useEffect(() => {
    const updateHeight = () => {
      if (ref.current) {
        setHeight(ref.current.offsetHeight);
      }
    };

    updateHeight();

    if (!ref.current) return;

    const resizeObserver = new ResizeObserver(() => {
      updateHeight();
    });

    resizeObserver.observe(ref.current);

    return () => resizeObserver.disconnect();
  }, []);

  return (
    <header
      className={cn(headerVariants({ displaySearchForm }), className)}
      ref={ref}
      style={{
        "--color-bg": backgroundColor,
      }}
    >
      {/* Logo - always first */}
      <div className="my-1 max-h-8 min-w-[100px] justify-self-start md:my-3">
        {logo}
      </div>

      {/* Search and Menu container on mobile, Menu only on desktop */}
      <div className="flex w-full min-w-[200px] items-center justify-end gap-2 justify-self-end md:min-w-[300px] md:content-center md:justify-center md:justify-self-center md:px-6 md:py-2">
        {displaySearchForm && (
          <div className="md:hidden">
            <SearchButton positionTop={height} />
          </div>
        )}
        <div className="md:w-full">{menu}</div>
      </div>

      {/* Search - desktop only (third position) */}
      {displaySearchForm && (
        <div className="hidden min-w-[50px] content-center text-right md:block">
          <SearchButton positionTop={height} />
        </div>
      )}
    </header>
  );
};

export default Header;
